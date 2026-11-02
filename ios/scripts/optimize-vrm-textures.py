#!/usr/bin/env python3
"""Resize embedded VRM textures with macOS sips; retain geometry and VRM metadata."""

import argparse
import json
from pathlib import Path
import struct
import subprocess
import tempfile


def read_glb(raw):
    magic, version, total = struct.unpack_from('<III', raw)
    if (magic, version, total) != (0x46546C67, 2, len(raw)):
        raise ValueError('Expected a GLB 2.0 file')
    size, kind = struct.unpack_from('<II', raw, 12)
    if kind != 0x4E4F534A:
        raise ValueError('Expected a JSON chunk')
    doc = json.loads(raw[20:20 + size])
    offset = 20 + size
    size, kind = struct.unpack_from('<II', raw, offset)
    if kind != 0x004E4942 or offset + 8 + size != len(raw):
        raise ValueError('Expected a single BIN chunk')
    if len(doc['buffers']) != 1 or 'uri' in doc['buffers'][0]:
        raise ValueError('Expected a single embedded buffer')
    return doc, raw[offset + 8:]


def payload(doc, binary, index):
    view = doc['bufferViews'][index]
    if view['buffer'] != 0:
        raise ValueError('External buffer is not supported')
    offset = view.get('byteOffset', 0)
    return binary[offset:offset + view['byteLength']]


def optimize(source, output, max_size):
    if source.resolve() == output.resolve():
        raise ValueError('Use a different output path to preserve the original')
    original = source.read_bytes()
    doc, binary = read_glb(original)
    replacements = {}
    report = []
    with tempfile.TemporaryDirectory(prefix='vrm-textures-') as directory:
        for index, image in enumerate(doc.get('images', [])):
            if image.get('mimeType') not in ('image/png', 'image/jpeg') or 'bufferView' not in image:
                raise ValueError('Only embedded PNG and JPEG images are supported')
            view_index = image['bufferView']
            if any(a.get('bufferView') == view_index for a in doc.get('accessors', [])):
                raise ValueError('An image bufferView is also used by geometry')
            path = Path(directory) / f'{index}.image'
            path.write_bytes(payload(doc, binary, view_index))
            info = subprocess.run(
                ['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', '-g', 'hasAlpha', str(path)],
                check=True, capture_output=True, text=True,
            ).stdout
            properties = dict(line.strip().split(': ', 1) for line in info.splitlines() if ': ' in line)
            width, height = int(properties['pixelWidth']), int(properties['pixelHeight'])
            if max(width, height) <= max_size:
                continue
            # JPEG は不透明な画像にだけ使う。透明な髪・まつ毛などは PNG のまま保つ。
            format_name = 'png' if properties['hasAlpha'] == 'yes' else 'jpeg'
            resized = Path(directory) / f'{index}.{format_name}'
            subprocess.run(
                ['sips', '-Z', str(max_size), '-s', 'format', format_name,
                 '-s', 'formatOptions', '90', str(path), '--out', str(resized)],
                check=True, capture_output=True, text=True,
            )
            replacements[view_index] = resized.read_bytes()
            image['mimeType'] = f'image/{format_name}'
            report.append({'name': image.get('name', str(index)), 'originalSize': [width, height],
                           'maxSize': max_size, 'mimeType': image['mimeType']})

    result = bytearray()
    for index, view in enumerate(doc['bufferViews']):
        result.extend(b'\0' * (-len(result) % 4))
        block = replacements.get(index, payload(doc, binary, index))
        view['byteOffset'] = len(result)
        view['byteLength'] = len(block)
        result.extend(block)
    doc['buffers'][0]['byteLength'] = len(result)
    result.extend(b'\0' * (-len(result) % 4))
    encoded = json.dumps(doc, ensure_ascii=False, separators=(',', ':')).encode()
    encoded += b' ' * (-len(encoded) % 4)
    raw = struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(result))
    raw += struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
    raw += struct.pack('<II', len(result), 0x004E4942) + result
    output.write_bytes(raw)
    print(json.dumps({'sourceBytes': len(original), 'outputBytes': len(raw), 'images': report},
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source', type=Path)
    parser.add_argument('output', type=Path)
    parser.add_argument('--max-size', type=int, default=2048)
    args = parser.parse_args()
    if args.max_size < 1:
        parser.error('--max-size must be positive')
    optimize(args.source, args.output, args.max_size)
