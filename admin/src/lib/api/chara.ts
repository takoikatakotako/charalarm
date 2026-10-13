import { apiGet, apiPost, apiPut } from "@/lib/api/client";
import type {
  CharaListResponse,
  Chara,
  CharaAssets,
  CharaCreate,
  CharaSettings,
  ResourceFileListResponse,
  UploadURLResponse,
} from "@/lib/api/types";

export async function fetchCharas(): Promise<CharaListResponse> {
  return apiGet<CharaListResponse>("/chara");
}

export async function fetchChara(charaID: string): Promise<Chara> {
  return apiGet<Chara>(`/chara/${encodeURIComponent(charaID)}`);
}

export async function createChara(chara: CharaCreate): Promise<Chara> {
  return apiPost<Chara>("/chara", chara);
}

export async function updateChara(
  charaID: string,
  settings: CharaSettings,
): Promise<Chara> {
  return apiPut<Chara>(`/chara/${encodeURIComponent(charaID)}`, settings);
}

function charaPath(charaID: string): string {
  return `/chara/${encodeURIComponent(charaID)}`;
}

export async function fetchResourceFiles(
  charaID: string,
): Promise<ResourceFileListResponse> {
  return apiGet<ResourceFileListResponse>(`${charaPath(charaID)}/files`);
}

/** 署名付き URL を取り、S3 に直接 PUT する */
export async function uploadResourceFile(
  charaID: string,
  file: File,
): Promise<void> {
  const { uploadURL, contentType } = await apiPost<UploadURLResponse>(
    `${charaPath(charaID)}/files/upload-url`,
    { fileName: file.name },
  );
  const response = await fetch(uploadURL, {
    method: "PUT",
    headers: { "Content-Type": contentType },
    body: file,
  });
  if (!response.ok) {
    throw new Error(`${file.name} のアップロードに失敗しました (${response.status})`);
  }
}

/** 上書きしたファイルを CloudFront のキャッシュから消す */
export async function invalidateResourceFiles(
  charaID: string,
  fileNames: string[],
): Promise<void> {
  await apiPost<void>(`${charaPath(charaID)}/files/invalidate`, { fileNames });
}

export async function updateCharaAssets(
  charaID: string,
  assets: CharaAssets,
): Promise<Chara> {
  return apiPut<Chara>(`${charaPath(charaID)}/assets`, assets);
}
