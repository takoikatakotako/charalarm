"""Run on macOS: python3 -m unittest discover -s ios/scripts/tests."""

import contextlib
import copy
import importlib.util
import io
import json
from pathlib import Path
import struct
import subprocess
import tempfile
import unittest
import zlib

SCRIPT = Path(__file__).resolve().parents[1] / 'optimize-vrm-textures.py'
SPEC = importlib.util.spec_from_file_location('optimizer', SCRIPT)
optimizer = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(optimizer)


def png(alpha):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))

    pixel = bytes([255, 0, 0, 128] if alpha else [255, 0, 0])
    scanlines = (b'\0' + pixel * 32) * 16
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', 32, 16, 8, 6 if alpha else 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(scanlines)) + chunk(b'IEND', b''))


class VRMTextureTests(unittest.TestCase):
    def test_resize_preserves_alpha_geometry_and_metadata(self):
        for alpha in [False, True]:
            with self.subTest(alpha=alpha), tempfile.TemporaryDirectory() as directory:
                geometry = b'geometry and morph target data\0\0\0'
                image = png(alpha)
                doc = {'asset': {'version': '2.0'}, 'buffers': [{'byteLength': len(geometry) + len(image)}],
                       'bufferViews': [{'buffer': 0, 'byteOffset': 0, 'byteLength': len(geometry)},
                                       {'buffer': 0, 'byteOffset': len(geometry), 'byteLength': len(image)}],
                       'accessors': [{'bufferView': 0}],
                       'images': [{'bufferView': 1, 'mimeType': 'image/png', 'name': 'face'}],
                       'extensions': {'VRMC_vrm': {'specVersion': '1.0', 'expressions': {'custom': {}}}}}
                encoded = json.dumps(doc).encode()
                encoded += b' ' * (-len(encoded) % 4)
                binary = geometry + image
                binary += b'\0' * (-len(binary) % 4)
                raw = struct.pack('<III', 0x46546C67, 2, 28 + len(encoded) + len(binary))
                raw += struct.pack('<II', len(encoded), 0x4E4F534A) + encoded
                raw += struct.pack('<II', len(binary), 0x004E4942) + binary
                source, output = Path(directory) / 'source.vrm', Path(directory) / 'output.vrm'
                source.write_bytes(raw)
                with contextlib.redirect_stdout(io.StringIO()):
                    optimizer.optimize(source, output, 16)
                result, result_binary = optimizer.read_glb(output.read_bytes())
                self.assertEqual(source.read_bytes(), raw)
                self.assertEqual(optimizer.payload(result, result_binary, 0), geometry)
                self.assertEqual(result['images'][0]['mimeType'], 'image/png' if alpha else 'image/jpeg')
                normalized = copy.deepcopy(result)
                for key in ['buffers', 'bufferViews', 'images']:
                    normalized[key] = doc[key]
                self.assertEqual(normalized, doc)
                for view in result['bufferViews']:
                    self.assertEqual(view['byteOffset'] % 4, 0)
                    self.assertLessEqual(view['byteOffset'] + view['byteLength'], result['buffers'][0]['byteLength'])
                texture = Path(directory) / 'resized.image'
                texture.write_bytes(optimizer.payload(result, result_binary, 1))
                info = subprocess.run(['sips', '-g', 'pixelWidth', '-g', 'pixelHeight', '-g', 'hasAlpha', str(texture)],
                                      check=True, capture_output=True, text=True).stdout
                self.assertIn('pixelWidth: 16', info)
                self.assertIn('pixelHeight: 8', info)
                self.assertIn('hasAlpha: yes' if alpha else 'hasAlpha: no', info)


if __name__ == '__main__':
    unittest.main()
