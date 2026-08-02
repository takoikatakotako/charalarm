import useSWR from "swr";
import { fetchCharas } from "@/lib/api/chara";
import type { CharaListResponse } from "@/lib/api/types";

export function useCharas() {
  return useSWR<CharaListResponse>("/chara", fetchCharas);
}
