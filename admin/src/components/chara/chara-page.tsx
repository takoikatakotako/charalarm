"use client";

import { useState, type ReactNode } from "react";
import useSWR from "swr";
import { toast } from "sonner";
import { useCharas } from "@/hooks/use-chara";
import { createChara, fetchResourceFiles, updateChara } from "@/lib/api/chara";
import { ApiClientError } from "@/lib/api/client";
import { LANGUAGES } from "@/lib/api/types";
import type {
  AppearanceType,
  Chara,
  CharaProfile,
  CharaSettings,
  ConversationType,
} from "@/lib/api/types";
import { CharaResources } from "@/components/chara/chara-resources";
import { CharaTapLines } from "@/components/chara/chara-tap-lines";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

const inputClass =
  "w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2";

const appearanceOptions: TypeOption<AppearanceType>[] = [
  {
    value: "illustration",
    label: "立ち絵",
    description: "表情ごとのイラスト（PNG）",
  },
  {
    value: "vrm",
    label: "3D（VRM）",
    description: "VRM のモデル。古いアプリ用に立ち絵も1枚用意する",
  },
];

const conversationOptions: TypeOption<ConversationType>[] = [
  {
    value: "none",
    label: "アラーム専用",
    description: "録音したボイスで電話をかけるだけ",
  },
  {
    value: "voicevox",
    label: "VOICEVOX",
    description: "端末内の VOICEVOX で合成して会話",
  },
  {
    value: "gemini",
    label: "Gemini",
    description: "サーバの Gemini TTS で合成して会話",
  },
];

/** 会話に使える言語。並びは第一言語の優先順 */
const languageOptions = LANGUAGES;

const emptySettings: CharaSettings = {
  enable: false,
  name: "",
  description: "",
  profiles: [],
  displayOrder: 0,
  appearanceType: "illustration",
  vrmFileName: "",
  conversationType: "none",
  conversationPrompt: "",
  voicevoxStyleID: 0,
  conversationLanguages: ["ja"],
  geminiVoice: "",
  geminiVoiceStyle: "",
  callOpeningPrompt: "",
  callEndingPrompt: "",
  callNoInputEndingPrompt: "",
};

function toSettings(chara: Chara): CharaSettings {
  return {
    enable: chara.enable,
    name: chara.name,
    description: chara.description,
    profiles: chara.profiles,
    displayOrder: chara.displayOrder,
    appearanceType: chara.appearanceType,
    vrmFileName: chara.vrmFileName,
    conversationType: chara.conversationType,
    conversationPrompt: chara.conversationPrompt,
    voicevoxStyleID: chara.voicevoxStyleID,
    conversationLanguages: chara.conversationLanguages,
    geminiVoice: chara.geminiVoice,
    geminiVoiceStyle: chara.geminiVoiceStyle,
    callOpeningPrompt: chara.callOpeningPrompt,
    callEndingPrompt: chara.callEndingPrompt,
    callNoInputEndingPrompt: chara.callNoInputEndingPrompt,
  };
}

function errorMessage(err: unknown, fallback: string): string {
  return err instanceof ApiClientError ? err.message : fallback;
}

interface TypeOption<T extends string> {
  value: T;
  label: string;
  description: string;
}

function TypeSelect<T extends string>({
  options,
  value,
  onChange,
}: {
  options: TypeOption<T>[];
  value: T;
  onChange: (value: T) => void;
}) {
  return (
    <div className="grid gap-2 sm:grid-cols-3">
      {options.map((option) => (
        <button
          key={option.value}
          type="button"
          onClick={() => onChange(option.value)}
          className={`rounded-md border px-3 py-2 text-left transition-colors ${
            value === option.value
              ? "border-primary bg-primary/5 ring-1 ring-primary"
              : "border-input hover:bg-muted"
          }`}
        >
          <div className="font-medium">{option.label}</div>
          <div className="text-xs text-muted-foreground">
            {option.description}
          </div>
        </button>
      ))}
    </div>
  );
}

function Field({
  label,
  hint,
  children,
}: {
  label: string;
  hint?: string;
  children: ReactNode;
}) {
  return (
    <div className="space-y-1.5">
      <label className="font-medium">{label}</label>
      {hint && <p className="text-xs text-muted-foreground">{hint}</p>}
      {children}
    </div>
  );
}

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="space-y-3 border-t pt-4">
      <h3 className="text-sm font-semibold">{title}</h3>
      {children}
    </section>
  );
}

function ProfilesEditor({
  profiles,
  onChange,
}: {
  profiles: CharaProfile[];
  onChange: (profiles: CharaProfile[]) => void;
}) {
  const update = (index: number, patch: Partial<CharaProfile>) =>
    onChange(profiles.map((p, i) => (i === index ? { ...p, ...patch } : p)));

  return (
    <div className="space-y-2">
      {profiles.map((profile, index) => (
        <div key={index} className="grid gap-2 sm:grid-cols-[8rem_1fr_1fr_auto]">
          <input
            className={inputClass}
            value={profile.title}
            placeholder="声優"
            onChange={(e) => update(index, { title: e.target.value })}
          />
          <input
            className={inputClass}
            value={profile.name}
            placeholder="名前"
            onChange={(e) => update(index, { name: e.target.value })}
          />
          <input
            className={inputClass}
            value={profile.url}
            placeholder="https://..."
            onChange={(e) => update(index, { url: e.target.value })}
          />
          <Button
            type="button"
            variant="ghost"
            onClick={() => onChange(profiles.filter((_, i) => i !== index))}
          >
            削除
          </Button>
        </div>
      ))}
      <Button
        type="button"
        variant="outline"
        size="sm"
        onClick={() => onChange([...profiles, { title: "", name: "", url: "" }])}
      >
        クレジットを追加
      </Button>
    </div>
  );
}

/** 見た目の1つ。そろっているか（アプリで選べるか）と、既定かどうかを出す */
function AppearanceCard({
  title,
  ready,
  readyText,
  notReadyText,
  isDefault,
  onSelectDefault,
  children,
}: {
  title: string;
  ready: boolean;
  readyText: string;
  notReadyText: string;
  isDefault: boolean;
  onSelectDefault: () => void;
  children?: ReactNode;
}) {
  return (
    <div
      className={`space-y-2 rounded-md border p-3 ${
        isDefault ? "border-primary ring-1 ring-primary" : "border-input"
      }`}
    >
      <div className="flex items-center justify-between gap-2">
        <span className="font-medium">{title}</span>
        <Badge variant={ready ? "secondary" : "outline"}>
          {ready ? "アプリで選べる" : "未設定"}
        </Badge>
      </div>
      <p className="text-xs text-muted-foreground">{ready ? readyText : notReadyText}</p>
      {children}
      <label className="flex items-center gap-2 text-xs">
        <input
          type="radio"
          checked={isDefault}
          onChange={onSelectDefault}
          className="h-3.5 w-3.5"
        />
        既定にする
      </label>
    </div>
  );
}

/** キャラの設定のフォーム。charaID を渡さなければ追加、渡せば編集 */
function CharaForm({
  chara,
  onSaved,
  onCancel,
}: {
  chara?: Chara;
  onSaved: () => void;
  onCancel?: () => void;
}) {
  const isNew = chara === undefined;
  const [charaID, setCharaID] = useState(chara?.charaID ?? "");
  const [settings, setSettings] = useState<CharaSettings>(
    chara ? toSettings(chara) : emptySettings,
  );
  const [saving, setSaving] = useState(false);
  // VRM のファイル名はアップロード済みの .vrm から選ぶ（追加する前のキャラにはファイルがない）
  const { data: files } = useSWR(
    chara ? `/chara/${chara.charaID}/files` : null,
    () => fetchResourceFiles(chara!.charaID),
  );
  const expressionImageCount = Object.values(chara?.expressions ?? {}).reduce(
    (count, e) => count + e.imageFileNames.length,
    0,
  );
  const vrmFiles = (files?.files ?? [])
    .map((f) => f.fileName)
    .filter((name) => name.toLowerCase().endsWith(".vrm"));

  const set = <K extends keyof CharaSettings>(key: K, value: CharaSettings[K]) =>
    setSettings((prev) => ({ ...prev, [key]: value }));

  const handleSave = async () => {
    setSaving(true);
    try {
      if (isNew) {
        await createChara({ charaID, ...settings });
        toast.success(`${settings.name} を追加しました`);
      } else {
        await updateChara(chara.charaID, settings);
        toast.success(`${settings.name} を更新しました`);
      }
      onSaved();
    } catch (err) {
      toast.error(errorMessage(err, "保存に失敗しました"));
    } finally {
      setSaving(false);
    }
  };

  const talks = settings.conversationType !== "none";

  return (
    <div className="space-y-4 text-sm">
      {isNew && (
        <Field
          label="charaID"
          hint="リバースドメイン形式（例: com.charalarm.yui）。リソースの置き場所にも使うので、あとから変えられない"
        >
          <input
            className={`${inputClass} font-mono`}
            value={charaID}
            placeholder="com.charalarm.xxx"
            onChange={(e) => setCharaID(e.target.value.trim())}
          />
        </Field>
      )}

      <label className="flex items-center gap-2">
        <input
          type="checkbox"
          checked={settings.enable}
          onChange={(e) => set("enable", e.target.checked)}
          className="h-4 w-4"
        />
        <span className="font-medium">
          有効（アプリのキャラ一覧に出し、ランダムなアラームにも使う）
        </span>
      </label>

      <div className="grid gap-4 sm:grid-cols-[1fr_8rem]">
        <Field label="名前">
          <input
            className={inputClass}
            value={settings.name}
            onChange={(e) => set("name", e.target.value)}
          />
        </Field>
        <Field label="表示順">
          <input
            className={inputClass}
            type="number"
            value={settings.displayOrder}
            onChange={(e) => set("displayOrder", Number(e.target.value) || 0)}
          />
        </Field>
      </div>
      <p className="-mt-2 text-xs text-muted-foreground">
        表示順は小さいほど一覧の先頭。同じなら charaID 順
      </p>

      <Field label="説明">
        <textarea
          className={`${inputClass} min-h-20 resize-y`}
          value={settings.description}
          onChange={(e) => set("description", e.target.value)}
        />
      </Field>

      <Field label="クレジット">
        <ProfilesEditor
          profiles={settings.profiles}
          onChange={(profiles) => set("profiles", profiles)}
        />
      </Field>

      <Section title="見た目（複数持てる）">
        <p className="text-xs text-muted-foreground">
          そろっている見た目は、すべてアプリで切り替えられる。「既定」はユーザーが選ぶ前に出す見た目
        </p>
        <div className="grid gap-3 sm:grid-cols-2">
          <AppearanceCard
            title="3D（VRM）"
            ready={settings.vrmFileName !== "" && vrmFiles.includes(settings.vrmFileName)}
            readyText={settings.vrmFileName}
            notReadyText={
              isNew
                ? "追加したあと、リソースタブで .vrm をアップロードして選ぶ"
                : "リソースタブでアップロードした .vrm を選ぶ"
            }
            isDefault={settings.appearanceType === "vrm"}
            onSelectDefault={() => set("appearanceType", "vrm")}
          >
            <select
              className={`${inputClass} font-mono`}
              value={settings.vrmFileName}
              disabled={isNew}
              onChange={(e) => set("vrmFileName", e.target.value)}
            >
              <option value="">なし</option>
              {/* 今の値がまだアップロードされていなくても選択肢に残す */}
              {settings.vrmFileName && !vrmFiles.includes(settings.vrmFileName) && (
                <option value={settings.vrmFileName}>{settings.vrmFileName}（ファイルがありません）</option>
              )}
              {vrmFiles.map((name) => (
                <option key={name} value={name}>
                  {name}
                </option>
              ))}
            </select>
          </AppearanceCard>
          <AppearanceCard
            title="イラスト"
            ready={expressionImageCount > 0}
            readyText={`表情の画像 ${expressionImageCount}枚`}
            notReadyText="リソースタブで画像を上げて、表情に登録する"
            isDefault={settings.appearanceType === "illustration"}
            onSelectDefault={() => set("appearanceType", "illustration")}
          />
        </div>
      </Section>

      <Section title="会話（1つ選ぶ）">
        <TypeSelect
          options={conversationOptions}
          value={settings.conversationType}
          onChange={(value) => {
            set("conversationType", value);
            if (value === "voicevox") set("conversationLanguages", ["ja"]);
          }}
        />
        {!talks && (
          <p className="text-xs text-muted-foreground">
            「VOICEVOX」か「Gemini」を選ぶと、人格プロンプトと声の欄が出る
          </p>
        )}

        {talks && (
          <Field
            label="人格プロンプト"
            hint="キャラの性格・口調。ここを変えるとアプリの更新なしで性格が変わる"
          >
            <textarea
              className={`${inputClass} min-h-32 resize-y font-mono`}
              value={settings.conversationPrompt}
              onChange={(e) => set("conversationPrompt", e.target.value)}
              placeholder="例: あなたはずんだの妖精のずんだもんです。語尾に「なのだ」をつけて…"
            />
          </Field>
        )}

        {talks && (
          <Field
            label="会話できる言語"
            hint="アプリで選んだ言語にキャラが対応していれば、その言語で話す。対応していなければ日本語で話す。VOICEVOX は日本語だけ"
          >
            <div className="flex flex-wrap gap-x-4 gap-y-2">
              {languageOptions.map((option) => {
                const checked = settings.conversationLanguages.includes(option.value);
                const disabled = settings.conversationType === "voicevox" && option.value !== "ja";
                return (
                  <label
                    key={option.value}
                    className={`flex items-center gap-2 ${disabled ? "text-muted-foreground" : ""}`}
                  >
                    <input
                      type="checkbox"
                      className="h-4 w-4"
                      checked={checked && !disabled}
                      disabled={disabled}
                      onChange={(e) =>
                        set(
                          "conversationLanguages",
                          languageOptions
                            .map((o) => o.value)
                            .filter((value) =>
                              value === option.value
                                ? e.target.checked
                                : settings.conversationLanguages.includes(value),
                            ),
                        )
                      }
                    />
                    {option.label}
                  </label>
                );
              })}
            </div>
          </Field>
        )}

        {settings.conversationType === "voicevox" && (
          <Field label="VOICEVOX のスタイル ID">
            <input
              className={`${inputClass} max-w-32`}
              type="number"
              min={0}
              value={settings.voicevoxStyleID}
              onChange={(e) => set("voicevoxStyleID", Number(e.target.value) || 0)}
            />
          </Field>
        )}

        {settings.conversationType === "gemini" && (
          <>
            <Field
              label="Gemini の声"
              hint="例: ja-jp-advisor-5、複製した声なら voice_...。空ならサーバの既定"
            >
              <input
                className={`${inputClass} font-mono`}
                value={settings.geminiVoice}
                onChange={(e) => set("geminiVoice", e.target.value.trim())}
              />
            </Field>
            <Field label="話し方の指示" hint="省略できる。例: 明るく、少し早口で">
              <input
                className={inputClass}
                value={settings.geminiVoiceStyle}
                onChange={(e) => set("geminiVoiceStyle", e.target.value)}
              />
            </Field>
          </>
        )}

        {talks && (
          <details className="space-y-3">
            <summary className="cursor-pointer font-medium">
              通話の場面のプロンプト（空ならサーバの既定）
            </summary>
            <div className="mt-3 space-y-3">
              <Field label="電話に出たとき">
                <textarea
                  className={`${inputClass} min-h-20 resize-y font-mono`}
                  value={settings.callOpeningPrompt}
                  onChange={(e) => set("callOpeningPrompt", e.target.value)}
                />
              </Field>
              <Field label="時間切れで切るとき">
                <textarea
                  className={`${inputClass} min-h-20 resize-y font-mono`}
                  value={settings.callEndingPrompt}
                  onChange={(e) => set("callEndingPrompt", e.target.value)}
                />
              </Field>
              <Field label="声が聞こえず切るとき">
                <textarea
                  className={`${inputClass} min-h-20 resize-y font-mono`}
                  value={settings.callNoInputEndingPrompt}
                  onChange={(e) => set("callNoInputEndingPrompt", e.target.value)}
                />
              </Field>
            </div>
          </details>
        )}
      </Section>

      {chara && (
        <div className="flex flex-wrap gap-x-6 gap-y-1 border-t pt-4 text-xs text-muted-foreground">
          <span>アラームのボイス: {chara.calls.length}件</span>
          <span>
            表情:{" "}
            {Object.keys(chara.expressions).join(", ") || "なし"}
          </span>
        </div>
      )}

      <div className="flex justify-end gap-2">
        {onCancel && (
          <Button type="button" variant="ghost" onClick={onCancel}>
            キャンセル
          </Button>
        )}
        <Button onClick={handleSave} disabled={saving}>
          {saving ? "保存中..." : isNew ? "追加" : "保存"}
        </Button>
      </div>
    </div>
  );
}

function typeLabel<T extends string>(options: TypeOption<T>[], value: T) {
  return options.find((o) => o.value === value)?.label ?? value;
}

/** そろっている見た目。VRM のファイル名があれば 3D、表情の画像があれば立ち絵。どちらもなければ既定だけ */
function availableAppearances(chara: Chara): AppearanceType[] {
  const types: AppearanceType[] = [];
  if (chara.vrmFileName) types.push("vrm");
  if (Object.values(chara.expressions).some((e) => e.imageFileNames.length > 0)) {
    types.push("illustration");
  }
  return types.length > 0 ? types : [chara.appearanceType];
}

function CharaCard({ chara, onSaved }: { chara: Chara; onSaved: () => void }) {
  const [open, setOpen] = useState(false);
  const [tab, setTab] = useState<"settings" | "resources" | "tapLines">("settings");

  return (
    <Card>
      <CardHeader>
        <button
          type="button"
          onClick={() => setOpen((v) => !v)}
          className="flex w-full items-start justify-between gap-4 text-left"
        >
          <div className="space-y-1">
            <CardTitle>{chara.name}</CardTitle>
            <p className="font-mono text-xs text-muted-foreground">
              {chara.charaID}
            </p>
          </div>
          <div className="flex flex-wrap justify-end gap-1.5">
            {!chara.enable && <Badge variant="destructive">無効</Badge>}
            {/* 見た目はそろっているものをすべて、会話は1つ */}
            {availableAppearances(chara).map((type) => (
              <Badge key={type} variant="secondary">
                {typeLabel(appearanceOptions, type)}
                {type === chara.appearanceType && availableAppearances(chara).length > 1 && "（既定）"}
              </Badge>
            ))}
            <Badge variant="secondary">
              会話: {typeLabel(conversationOptions, chara.conversationType)}
            </Badge>
            <Badge variant="outline">順 {chara.displayOrder}</Badge>
          </div>
        </button>
      </CardHeader>
      {open && (
        <CardContent className="space-y-4">
          <div className="flex gap-1 border-b">
            {(
              [
                ["settings", "設定"],
                ["resources", "リソース"],
                ["tapLines", "タップのセリフ"],
              ] as const
            ).map(([value, label]) => (
              <button
                key={value}
                type="button"
                onClick={() => setTab(value)}
                className={`-mb-px border-b-2 px-3 py-1.5 text-sm ${
                  tab === value
                    ? "border-primary font-medium"
                    : "border-transparent text-muted-foreground"
                }`}
              >
                {label}
              </button>
            ))}
          </div>
          {tab === "settings" && <CharaForm chara={chara} onSaved={onSaved} />}
          {tab === "resources" && <CharaResources chara={chara} onSaved={onSaved} />}
          {tab === "tapLines" && <CharaTapLines chara={chara} onSaved={onSaved} />}
        </CardContent>
      )}
    </Card>
  );
}

export function CharaPage() {
  const { data, error, isLoading, mutate } = useCharas();
  const [adding, setAdding] = useState(false);
  const charas = data?.charas ?? [];

  return (
    <div className="mx-auto max-w-3xl space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">キャラクター</h1>
        {!adding && <Button onClick={() => setAdding(true)}>キャラを追加</Button>}
      </div>

      {adding && (
        <Card>
          <CardHeader>
            <CardTitle>キャラを追加</CardTitle>
            <p className="text-xs text-muted-foreground">
              無効のまま追加し、リソースをそろえてから有効にする
            </p>
          </CardHeader>
          <CardContent>
            <CharaForm
              onSaved={() => {
                setAdding(false);
                mutate();
              }}
              onCancel={() => setAdding(false)}
            />
          </CardContent>
        </Card>
      )}

      {isLoading && <p className="text-muted-foreground">読み込み中...</p>}
      {error && <p className="text-destructive">エラーが発生しました</p>}

      {data && charas.length === 0 && (
        <p className="text-muted-foreground">キャラクターがいません</p>
      )}

      <div className="space-y-4">
        {charas.map((chara) => (
          <CharaCard
            key={chara.charaID}
            chara={chara}
            onSaved={() => mutate()}
          />
        ))}
      </div>
    </div>
  );
}
