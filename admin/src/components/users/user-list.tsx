"use client";

import { useState } from "react";
import { useUsers } from "@/hooks/use-users";
import { UserTable } from "@/components/users/user-table";
import { Button } from "@/components/ui/button";
import { ChevronLeft, ChevronRight } from "lucide-react";

const PAGE_SIZE = 20;

export function UserList() {
  // cursor[i] が i ページ目を取得するための cursor (0ページ目は null)
  const [cursors, setCursors] = useState<(string | null)[]>([null]);
  const [pageIndex, setPageIndex] = useState(0);

  const { data, error, isLoading } = useUsers(PAGE_SIZE, cursors[pageIndex]);

  const handleNext = () => {
    if (!data?.nextCursor) return;
    const next = pageIndex + 1;
    setCursors((prev) => {
      if (prev[next] === data.nextCursor) return prev;
      const updated = [...prev];
      updated[next] = data.nextCursor ?? null;
      return updated;
    });
    setPageIndex(next);
  };

  const handlePrev = () => {
    if (pageIndex === 0) return;
    setPageIndex(pageIndex - 1);
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">ユーザー一覧</h1>
      </div>

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラーが発生しました</p>}

      {data && (
        <>
          {data.users.length === 0 ? (
            <p className="text-muted-foreground">ユーザーがいません</p>
          ) : (
            <UserTable users={data.users} />
          )}

          <div className="flex items-center justify-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={handlePrev}
              disabled={pageIndex === 0}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="text-sm text-muted-foreground">
              {pageIndex + 1} ページ目
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={handleNext}
              disabled={!data.nextCursor}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
