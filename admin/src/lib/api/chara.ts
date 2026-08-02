import { apiGet } from "@/lib/api/client";
import type { CharaListResponse, Chara } from "@/lib/api/types";

export async function fetchCharas(): Promise<CharaListResponse> {
  return apiGet<CharaListResponse>("/chara");
}

export async function fetchChara(charaID: string): Promise<Chara> {
  return apiGet<Chara>(`/chara/${encodeURIComponent(charaID)}`);
}
