import { apiGet, apiPut } from "@/lib/api/client";
import type { CharaListResponse, Chara, CharaUpdate } from "@/lib/api/types";

export async function fetchCharas(): Promise<CharaListResponse> {
  return apiGet<CharaListResponse>("/chara");
}

export async function fetchChara(charaID: string): Promise<Chara> {
  return apiGet<Chara>(`/chara/${encodeURIComponent(charaID)}`);
}

export async function updateChara(
  charaID: string,
  update: CharaUpdate,
): Promise<Chara> {
  return apiPut<Chara>(`/chara/${encodeURIComponent(charaID)}`, update);
}
