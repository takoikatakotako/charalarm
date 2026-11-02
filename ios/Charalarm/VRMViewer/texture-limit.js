// GPU にアップロードする前に縮める。同じ Source を使う MToon の複製にも反映される。
export function limitTextureSize(textures, maxSize) {
  const resized = new Map();
  for (const texture of textures) {
    const image = texture?.image;
    if (!image || Math.max(image.width, image.height) <= maxSize) continue;

    let canvas = resized.get(image);
    if (!canvas) {
      const scale = maxSize / Math.max(image.width, image.height);
      canvas = document.createElement('canvas');
      canvas.width = Math.max(1, Math.round(image.width * scale));
      canvas.height = Math.max(1, Math.round(image.height * scale));
      const context = canvas.getContext('2d');
      if (!context) throw new Error('テクスチャを縮小できませんでした');
      context.drawImage(image, 0, 0, canvas.width, canvas.height);
      resized.set(image, canvas);
    }
    texture.image = canvas;
    texture.needsUpdate = true;
  }
  // 縮める前の大きい画像 (ImageBitmap) は、ガベージコレクションを待たずにすぐ手放す。
  // WKWebView の User-Agent には Safari と入らないので、GLTFLoader は ImageBitmap で読み込む
  for (const image of resized.keys()) {
    image.close?.();
  }
}
