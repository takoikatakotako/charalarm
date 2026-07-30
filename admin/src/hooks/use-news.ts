import useSWR from "swr";
import { fetchNews } from "@/lib/api/news";
import type { NewsListResponse } from "@/lib/api/types";

export function useNews() {
  return useSWR<NewsListResponse>("/news", fetchNews);
}
