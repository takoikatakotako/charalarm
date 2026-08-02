"use client";

import { useState } from "react";
import { toast } from "sonner";
import { useCharas } from "@/hooks/use-chara";
import { updateChara } from "@/lib/api/chara";
import { ApiClientError } from "@/lib/api/client";
import type { Chara } from "@/lib/api/types";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const inputClass =
  "w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2";

function CharaEditor({ chara, onSaved }: { chara: Chara; onSaved: () => void }) {
  const [enable, setEnable] = useState(chara.enable);
  const [name, setName] = useState(chara.name);
  const [description, setDescription] = useState(chara.description);
  const [prompt, setPrompt] = useState(chara.conversationPrompt);
  const [styleId, setStyleId] = useState(String(chara.voicevoxStyleID));
  const [saving, setSaving] = useState(false);

  const handleSave = async () => {
    setSaving(true);
    try {
      await updateChara(chara.charaID, {
        enable,
        name,
        description,
        conversationPrompt: prompt,
        voicevoxStyleID: Number(styleId) || 0,
      });
      toast.success(`${name} を更新しました`);
      onSaved();
    } catch (err) {
      const message =
        err instanceof ApiClientError ? err.message : "更新に失敗しました";
      toast.error(message);
    } finally {
      setSaving(false);
    }
  };

  const expressionNames = Object.keys(chara.expressions);

  return (
    <Card>
      <CardHeader>
        <CardTitle>{chara.name}</CardTitle>
        <p className="font-mono text-xs text-muted-foreground">
          {chara.charaID}
        </p>
      </CardHeader>
      <CardContent className="space-y-4 text-sm">
        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={enable}
            onChange={(e) => setEnable(e.target.checked)}
            className="h-4 w-4"
          />
          <span className="font-medium">有効（アプリのキャラ一覧に表示）</span>
        </label>

        <div className="space-y-1.5">
          <label className="font-medium">名前</label>
          <input
            className={inputClass}
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
        </div>

        <div className="space-y-1.5">
          <label className="font-medium">説明</label>
          <textarea
            className={`${inputClass} min-h-20 resize-y`}
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </div>

        <div className="space-y-1.5">
          <label className="font-medium">会話プロンプト（人格）</label>
          <p className="text-xs text-muted-foreground">
            空でないキャラは音声会話に対応。ここを変えるとアプリ更新なしで性格が変わる。
          </p>
          <textarea
            className={`${inputClass} min-h-32 resize-y font-mono`}
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="例: あなたはずんだの妖精のずんだもんです。語尾に「なのだ」をつけて…"
          />
        </div>

        <div className="space-y-1.5">
          <label className="font-medium">VOICEVOX styleId</label>
          <input
            className={`${inputClass} max-w-32`}
            type="number"
            value={styleId}
            onChange={(e) => setStyleId(e.target.value)}
          />
        </div>

        <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-muted-foreground">
          <span>コール: {chara.calls.length}件</span>
          <span>
            表情: {expressionNames.length > 0 ? expressionNames.join(", ") : "なし"}
          </span>
          <span>クレジット: {chara.profiles.map((p) => p.name).join(" / ") || "なし"}</span>
        </div>

        <div className="flex justify-end">
          <Button onClick={handleSave} disabled={saving}>
            {saving ? "保存中..." : "保存"}
          </Button>
        </div>
      </CardContent>
    </Card>
  );
}

export function CharaPage() {
  const { data, error, isLoading, mutate } = useCharas();
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
          <CharaEditor
            key={chara.charaID}
            chara={chara}
            onSaved={() => mutate()}
          />
        ))}
      </div>
    </div>
  );
}
