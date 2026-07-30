"use client";

import { useState } from "react";
import { toast } from "sonner";
import { useNews } from "@/hooks/use-news";
import { createNews, deleteNews } from "@/lib/api/news";
import { ApiClientError } from "@/lib/api/client";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Trash2 } from "lucide-react";

const inputClass =
  "w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50";

function formatDate(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toLocaleString("ja-JP");
}

export function NewsPage() {
  const { data, error, isLoading, mutate } = useNews();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  const canSubmit = title.trim() !== "" && body.trim() !== "" && !submitting;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;
    setSubmitting(true);
    try {
      await createNews(title.trim(), body.trim());
      toast.success("お知らせを配信しました");
      setTitle("");
      setBody("");
      await mutate();
    } catch (err) {
      const message =
        err instanceof ApiClientError ? err.message : "配信に失敗しました";
      toast.error(message);
    } finally {
      setSubmitting(false);
    }
  };

  const handleDelete = async (newsId: string) => {
    if (!window.confirm("このお知らせを削除しますか？")) return;
    setDeletingId(newsId);
    try {
      await deleteNews(newsId);
      toast.success("お知らせを削除しました");
      await mutate();
    } catch (err) {
      const message =
        err instanceof ApiClientError ? err.message : "削除に失敗しました";
      toast.error(message);
    } finally {
      setDeletingId(null);
    }
  };

  const newsList = data?.news ?? [];

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <h1 className="text-2xl font-bold">お知らせ配信</h1>

      <Card>
        <CardHeader>
          <CardTitle>新規配信</CardTitle>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="space-y-1.5">
              <label htmlFor="news-title" className="text-sm font-medium">
                タイトル
              </label>
              <input
                id="news-title"
                className={inputClass}
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                placeholder="例: v4.1 をリリースしました"
                maxLength={100}
                disabled={submitting}
              />
            </div>
            <div className="space-y-1.5">
              <label htmlFor="news-body" className="text-sm font-medium">
                本文
              </label>
              <textarea
                id="news-body"
                className={`${inputClass} min-h-32 resize-y`}
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="お知らせの本文を入力してください"
                disabled={submitting}
              />
            </div>
            <div className="flex justify-end">
              <Button type="submit" disabled={!canSubmit}>
                {submitting ? "配信中..." : "配信する"}
              </Button>
            </div>
          </form>
        </CardContent>
      </Card>

      <div className="space-y-3">
        <h2 className="text-lg font-semibold">配信済み</h2>

        {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
        {error && <p className="text-destructive">エラーが発生しました</p>}

        {data && newsList.length === 0 && (
          <p className="text-muted-foreground">お知らせはまだありません</p>
        )}

        {newsList.map((news) => (
          <Card key={news.newsId}>
            <CardContent className="flex items-start justify-between gap-4 py-4">
              <div className="min-w-0 space-y-1">
                <p className="font-medium">{news.title}</p>
                <p className="whitespace-pre-wrap break-words text-sm text-muted-foreground">
                  {news.body}
                </p>
                <p className="text-xs text-muted-foreground">
                  {formatDate(news.registeredAt)}
                </p>
              </div>
              <Button
                variant="outline"
                size="sm"
                onClick={() => handleDelete(news.newsId)}
                disabled={deletingId === news.newsId}
                aria-label="削除"
              >
                <Trash2 className="h-4 w-4" />
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}
