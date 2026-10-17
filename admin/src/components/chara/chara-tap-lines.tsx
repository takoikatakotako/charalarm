"use client";

import { useState, type ReactNode } from "react";
import useSWR from "swr";
import { toast } from "sonner";
import {
  createTapLineDrafts,
  createTapLineVoices,
  fetchResourceFiles,
  fetchTapLineThemes,
  saveTapLines,
} from "@/lib/api/chara";
import { ApiClientError } from "@/lib/api/client";
import type { Chara, TapLine, TapLineTheme, TapLineWhen } from "@/lib/api/types";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";

const inputClass =
  "w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2";

const weekdayLabels = ["日", "月", "火", "水", "木", "金", "土"];
/** 一度に作るボイスの数（管理 API の上限。Lambda と CloudFront の時間の上限 30 秒に収める） */
const voicesPerCall = 4;

function errorMessage(err: unknown, fallback: string): string {
  if (err instanceof ApiClientError || err instanceof Error) return err.message;
  return fallback;
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="space-y-3 border-t pt-4">
      <h3 className="text-sm font-semibold">{title}</h3>
      {children}
    </section>
  );
}

/** 条件を短い言葉にする（例: 12-24, 12-25 / 5〜11時 / 日・土） */
function describeWhen(when: TapLineWhen): string {
  const parts: string[] = [];
  if (when.dates.length > 0) parts.push(when.dates.join(", "));
  if (when.hours.length === 2) parts.push(`${when.hours[0]}〜${when.hours[1]}時`);
  if (when.weekdays.length > 0) parts.push(when.weekdays.map((d) => weekdayLabels[d]).join("・"));
  return parts.length > 0 ? parts.join(" / ") : "いつでも";
}

/** 条件を直す欄 */
function WhenEditor({ when, onChange }: { when: TapLineWhen; onChange: (when: TapLineWhen) => void }) {
  return (
    <div className="grid gap-2 text-xs sm:grid-cols-3">
      <label className="space-y-1">
        <span className="text-muted-foreground">日付（MM-DD、カンマ区切り）</span>
        <input
          className={`${inputClass} font-mono`}
          value={when.dates.join(", ")}
          placeholder="12-24, 12-25"
          onChange={(e) =>
            onChange({
              ...when,
              dates: e.target.value
                .split(",")
                .map((d) => d.trim())
                .filter((d) => d !== ""),
            })
          }
        />
      </label>
      <label className="space-y-1">
        <span className="text-muted-foreground">時間帯（開始〜終了の時）</span>
        <div className="flex items-center gap-1">
          <input
            className={inputClass}
            type="number"
            min={0}
            max={23}
            value={when.hours[0] ?? ""}
            onChange={(e) =>
              onChange({
                ...when,
                hours: e.target.value === "" ? [] : [Number(e.target.value), when.hours[1] ?? 24],
              })
            }
          />
          <span>〜</span>
          <input
            className={inputClass}
            type="number"
            min={1}
            max={24}
            value={when.hours[1] ?? ""}
            onChange={(e) =>
              onChange({
                ...when,
                hours: e.target.value === "" ? [] : [when.hours[0] ?? 0, Number(e.target.value)],
              })
            }
          />
        </div>
      </label>
      <div className="space-y-1">
        <span className="text-muted-foreground">曜日</span>
        <div className="flex gap-1">
          {weekdayLabels.map((label, day) => {
            const on = when.weekdays.includes(day);
            return (
              <button
                key={day}
                type="button"
                onClick={() =>
                  onChange({
                    ...when,
                    weekdays: on
                      ? when.weekdays.filter((d) => d !== day)
                      : [...when.weekdays, day].sort(),
                  })
                }
                className={`h-8 w-8 rounded-md border ${on ? "border-primary bg-primary/10" : "border-input"}`}
              >
                {label}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}

/** トップでキャラをタップしたときのセリフ。LLM で案を作り、選んで、Gemini TTS でボイスを作る */
export function CharaTapLines({ chara, onSaved }: { chara: Chara; onSaved: () => void }) {
  const { data: themesData } = useSWR("/tap-line-themes", fetchTapLineThemes);
  const themes: TapLineTheme[] = themesData?.themes ?? [];
  const { data: files } = useSWR(`/chara/${chara.charaID}/files`, () => fetchResourceFiles(chara.charaID));

  const [lines, setLines] = useState<TapLine[]>(chara.tapLines ?? []);
  const [dirty, setDirty] = useState(false);
  const [theme, setTheme] = useState("anytime");
  const [count, setCount] = useState(10);
  const [language, setLanguage] = useState("ja");
  const [drafts, setDrafts] = useState<TapLine[]>([]);
  const [picked, setPicked] = useState<Set<number>>(new Set());
  const [busy, setBusy] = useState<"" | "drafts" | "save" | "voices">("");
  const [editing, setEditing] = useState<number | null>(null);

  const canMakeVoices = chara.conversationType === "gemini";
  const themeLabel = (key: string) => themes.find((t) => t.key === key)?.label ?? (key || "いつでも");
  const withoutVoice = lines.filter((line) => line.id !== "" && line.voiceFileName === "");

  const updateLine = (index: number, patch: Partial<TapLine>) => {
    setLines((prev) => prev.map((line, i) => (i === index ? { ...line, ...patch } : line)));
    setDirty(true);
  };

  const handleDrafts = async () => {
    setBusy("drafts");
    try {
      const { drafts } = await createTapLineDrafts(chara.charaID, theme, count, language);
      setDrafts(drafts);
      setPicked(new Set(drafts.map((_, i) => i)));
      if (drafts.length === 0) toast.error("使える案がありませんでした。もう一度作ってください");
    } catch (err) {
      toast.error(errorMessage(err, "案を作れませんでした"));
    } finally {
      setBusy("");
    }
  };

  const addPicked = () => {
    const added = drafts.filter((_, i) => picked.has(i));
    setLines((prev) => [...prev, ...added]);
    setDrafts([]);
    setPicked(new Set());
    setDirty(true);
    toast.success(`${added.length}個を足しました。保存してください`);
  };

  const handleSave = async () => {
    setBusy("save");
    try {
      const updated = await saveTapLines(chara.charaID, lines);
      setLines(updated.tapLines);
      setDirty(false);
      toast.success("セリフを保存しました");
      onSaved();
    } catch (err) {
      toast.error(errorMessage(err, "保存できませんでした"));
    } finally {
      setBusy("");
    }
  };

  const handleVoices = async () => {
    setBusy("voices");
    let current = lines;
    try {
      const ids = withoutVoice.map((line) => line.id);
      for (let i = 0; i < ids.length; i += voicesPerCall) {
        const updated = await createTapLineVoices(chara.charaID, ids.slice(i, i + voicesPerCall));
        current = updated.tapLines;
        setLines(current);
        toast.message(`ボイスを作っています… ${Math.min(i + voicesPerCall, ids.length)} / ${ids.length}`);
      }
      toast.success("ボイスを作りました");
      onSaved();
    } catch (err) {
      toast.error(errorMessage(err, "ボイスを作れませんでした"));
    } finally {
      setBusy("");
    }
  };

  return (
    <div className="space-y-4 text-sm">
      <p className="text-xs text-muted-foreground">
        トップでキャラをタップしたときに流すセリフ。アプリは今の日時に合う条件つきのセリフを優先して流す。
        ボイスは公開のリソース（S3 + CloudFront）に置くので、ユーザーの情報は入れない（作るときに、個人情報に見えるものがないかも確かめる）
      </p>

      <Section title="案を作る（LLM）">
        <div className="flex flex-wrap items-end gap-2">
          <label className="space-y-1">
            <span className="block text-xs text-muted-foreground">テーマ</span>
            <select className={inputClass} value={theme} onChange={(e) => setTheme(e.target.value)}>
              {themes.map((t) => (
                <option key={t.key} value={t.key}>
                  {t.label}（{describeWhen(t.when)}）
                </option>
              ))}
            </select>
          </label>
          <label className="space-y-1">
            <span className="block text-xs text-muted-foreground">言語</span>
            <select className={inputClass} value={language} onChange={(e) => setLanguage(e.target.value)}>
              <option value="ja">日本語</option>
              <option value="en">English</option>
            </select>
          </label>
          <label className="space-y-1">
            <span className="block text-xs text-muted-foreground">数</span>
            <input
              className={`${inputClass} w-20`}
              type="number"
              min={1}
              max={20}
              value={count}
              onChange={(e) => setCount(Number(e.target.value) || 1)}
            />
          </label>
          <Button onClick={handleDrafts} disabled={busy !== ""}>
            {busy === "drafts" ? "作っています..." : "案を作る"}
          </Button>
        </div>

        {drafts.length > 0 && (
          <div className="space-y-2 rounded-md border p-3">
            {drafts.map((draft, i) => (
              <label key={i} className="flex items-start gap-2">
                <input
                  type="checkbox"
                  className="mt-1 h-4 w-4"
                  checked={picked.has(i)}
                  onChange={(e) =>
                    setPicked((prev) => {
                      const next = new Set(prev);
                      if (e.target.checked) next.add(i);
                      else next.delete(i);
                      return next;
                    })
                  }
                />
                <span>{draft.text}</span>
              </label>
            ))}
            <div className="flex justify-end gap-2">
              <Button variant="ghost" onClick={() => setDrafts([])}>
                捨てる
              </Button>
              <Button variant="outline" onClick={addPicked} disabled={picked.size === 0}>
                選んだ {picked.size} 個を足す
              </Button>
            </div>
          </div>
        )}
      </Section>

      <Section title={`セリフ（${lines.length}個、ボイスあり ${lines.filter((l) => l.voiceFileName).length}個）`}>
        {lines.length === 0 && <p className="text-xs text-muted-foreground">まだセリフがありません</p>}
        <ul className="space-y-2">
          {lines.map((line, index) => (
            <li key={line.id || `new-${index}`} className="space-y-2 rounded-md border p-2">
              <div className="flex items-start gap-2">
                <input
                  className={inputClass}
                  value={line.text}
                  onChange={(e) => updateLine(index, { text: e.target.value })}
                />
                <Button variant="ghost" size="sm" onClick={() => setEditing(editing === index ? null : index)}>
                  条件
                </Button>
                <Button
                  variant="ghost"
                  size="sm"
                  onClick={() => {
                    setLines((prev) => prev.filter((_, i) => i !== index));
                    setDirty(true);
                  }}
                >
                  削除
                </Button>
              </div>
              <div className="flex flex-wrap items-center gap-2 text-xs text-muted-foreground">
                <Badge variant="outline">{line.language === "en" ? "English" : "日本語"}</Badge>
                <Badge variant="outline">{themeLabel(line.theme)}</Badge>
                <span>{describeWhen(line.when)}</span>
                {line.voiceFileName && files ? (
                  <audio
                    controls
                    preload="none"
                    className="h-7"
                    src={`${files.baseURL}/${chara.charaID}/${line.voiceFileName}`}
                  />
                ) : (
                  <Badge variant="secondary">ボイスなし</Badge>
                )}
              </div>
              {editing === index && (
                <WhenEditor when={line.when} onChange={(when) => updateLine(index, { when })} />
              )}
            </li>
          ))}
        </ul>
      </Section>

      <div className="flex flex-wrap items-center justify-end gap-2">
        {!canMakeVoices && (
          <span className="text-xs text-muted-foreground">
            ボイスを作れるのは会話が Gemini のキャラだけ（ほかはリソースタブで上げる）
          </span>
        )}
        <Button
          variant="outline"
          onClick={handleVoices}
          disabled={busy !== "" || dirty || !canMakeVoices || withoutVoice.length === 0}
        >
          {busy === "voices" ? "作っています..." : `ボイスを作る（${withoutVoice.length}個）`}
        </Button>
        <Button onClick={handleSave} disabled={busy !== "" || !dirty}>
          {busy === "save" ? "保存中..." : "保存"}
        </Button>
      </div>
      {dirty && <p className="text-right text-xs text-muted-foreground">ボイスを作る前に保存してください</p>}
    </div>
  );
}
