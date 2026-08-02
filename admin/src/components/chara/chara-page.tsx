"use client";

import { useCharas } from "@/hooks/use-chara";
import type { Chara } from "@/lib/api/types";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

function CharaCard({ chara }: { chara: Chara }) {
  const expressionNames = Object.keys(chara.expressions);
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center gap-2">
          <CardTitle>{chara.name}</CardTitle>
          <Badge variant={chara.enable ? "default" : "secondary"}>
            {chara.enable ? "有効" : "無効"}
          </Badge>
        </div>
        <p className="font-mono text-xs text-muted-foreground">
          {chara.charaID}
        </p>
      </CardHeader>
      <CardContent className="space-y-4 text-sm">
        <p className="whitespace-pre-wrap break-words">{chara.description}</p>

        {chara.profiles.length > 0 && (
          <div className="space-y-1">
            <p className="font-medium">クレジット</p>
            <ul className="space-y-0.5 text-muted-foreground">
              {chara.profiles.map((p, i) => (
                <li key={i}>
                  <span className="text-foreground">{p.title}</span>：{p.name}
                  {p.url && (
                    <a
                      href={p.url}
                      target="_blank"
                      rel="noreferrer"
                      className="ml-2 underline hover:text-foreground"
                    >
                      link
                    </a>
                  )}
                </li>
              ))}
            </ul>
          </div>
        )}

        <div className="flex flex-wrap gap-x-6 gap-y-1 text-muted-foreground">
          <span>コール: {chara.calls.length}件</span>
          <span>
            表情: {expressionNames.length > 0 ? expressionNames.join(", ") : "なし"}
          </span>
        </div>

        <p className="text-xs text-muted-foreground">更新: {chara.updatedAt}</p>
      </CardContent>
    </Card>
  );
}

export function CharaPage() {
  const { data, error, isLoading } = useCharas();
  const charas = data?.charas ?? [];

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <h1 className="text-2xl font-bold">キャラクター</h1>

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラーが発生しました</p>}

      {data && charas.length === 0 && (
        <p className="text-muted-foreground">キャラクターがいません</p>
      )}

      <div className="space-y-4">
        {charas.map((chara) => (
          <CharaCard key={chara.charaID} chara={chara} />
        ))}
      </div>
    </div>
  );
}
