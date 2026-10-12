import { apiGet, apiPost, apiPut } from "@/lib/api/client";
import type {
  CharaListResponse,
  Chara,
  CharaCreate,
  CharaSettings,
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
