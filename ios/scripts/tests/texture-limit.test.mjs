import assert from 'node:assert/strict';
import { test } from 'node:test';
import { Texture, SRGBColorSpace } from '../../Charalarm/VRMViewer/lib/three/three.core.js';
import { limitTextureSize } from '../../Charalarm/VRMViewer/texture-limit.js';

function canvasDocument(draws) {
  return {
    createElement(name) {
      assert.equal(name, 'canvas');
      return { width: 0, height: 0, getContext: () => ({ drawImage: (...args) => draws.push(args) }) };
    },
  };
}

test('resize shared MToon sources once, preserving texture settings and aspect ratio', () => {
  const draws = [];
  globalThis.document = canvasDocument(draws);
  const image = { width: 4096, height: 2048 };
  const texture = new Texture(image);
  texture.flipY = false;
  texture.colorSpace = SRGBColorSpace;
  texture.offset.set(0.2, 0.3);
  const outline = texture.clone();
  const shade = new Texture(image); // 同じ画像、別の Source
  const version = texture.version;

  limitTextureSize([texture, outline, shade], 2048);

  assert.equal(draws.length, 1);
  assert.deepEqual(draws[0], [image, 0, 0, 2048, 1024]);
  assert.equal(texture.image.width, 2048);
  assert.equal(texture.image.height, 1024);
  assert.equal(outline.image, texture.image);
  assert.equal(shade.image, texture.image);
  assert.equal(texture.flipY, false);
  assert.equal(texture.colorSpace, SRGBColorSpace);
  assert.deepEqual(texture.offset.toArray(), [0.2, 0.3]);
  assert.ok(texture.version > version);

  limitTextureSize([texture, outline, shade], 2048);
  assert.equal(draws.length, 1);
});

test('respect a smaller GPU limit; leave small textures and null entries alone', () => {
  const draws = [];
  globalThis.document = canvasDocument(draws);
  const small = new Texture({ width: 512, height: 1024 });
  const smallImage = small.image;
  const large = new Texture({ width: 2048, height: 4096 });

  limitTextureSize([null, new Texture(), small, large], 1024);

  assert.equal(small.image, smallImage);
  assert.equal(small.version, 0);
  assert.equal(large.image.width, 512);
  assert.equal(large.image.height, 1024);
});

test('report canvas allocation failure instead of rendering oversized textures', () => {
  globalThis.document = { createElement: () => ({ getContext: () => null }) };
  assert.throws(() => limitTextureSize([new Texture({ width: 4096, height: 4096 })], 2048),
    /テクスチャを縮小できませんでした/);
});

test('close the original image bitmaps after resizing', () => {
  globalThis.document = canvasDocument([]);
  let closed = 0;
  const bitmap = { width: 4096, height: 4096, close: () => { closed += 1; } };
  const small = { width: 1024, height: 1024, close: () => { closed += 100; } };
  limitTextureSize([new Texture(bitmap), new Texture(bitmap), new Texture(small)], 2048);
  assert.equal(closed, 1);
});
