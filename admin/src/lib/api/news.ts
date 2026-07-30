import { apiGet, apiPost, apiDelete } from "@/lib/api/client";
import type { News, NewsListResponse } from "@/lib/api/types";

export async function fetchNews(): Promise<NewsListResponse> {
  return apiGet<NewsListResponse>("/news");
}

export async function createNews(title: string, body: string): Promise<News> {
  return apiPost<News>("/news", { title, body });
}

export async function deleteNews(newsId: string): Promise<void> {
  return apiDelete(`/news/${encodeURIComponent(newsId)}`);
}
