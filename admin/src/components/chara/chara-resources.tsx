"use client";

import { useRef, useState, type ReactNode } from "react";
import useSWR from "swr";
import { toast } from "sonner";
import {
  fetchResourceFiles,
  invalidateResourceFiles,
  updateCharaAssets,
  uploadResourceFile,
} from "@/lib/api/chara";
import { ApiClientError } from "@/lib/api/client";
import type {
  Chara,
  CharaCall,
  CharaExpression,
  ResourceFile,
} from "@/lib/api/types";
import { Button } from "@/components/ui/button";

const inputClass =
  "w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2";

const imageExtensions = [".png", ".jpg", ".jpeg"];
const voiceExtensions = [".caf", ".mp3", ".m4a", ".wav"];

function hasExtension(fileName: string, extensions: string[]): boolean {
  const lower = fileName.toLowerCase();
  return extensions.some((ext) => lower.endsWith(ext));
}

function formatSize(bytes: number): string {
  if (bytes >= 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)}MB`;
  return `${Math.ceil(bytes / 1024)}KB`;
}

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

/** ファイル名をチップで選ぶ（複数可） */
function FilePicker({
  files,
  selected,
  onChange,
}: {
  files: string[];
  selected: string[];
  onChange: (selected: string[]) => void;
}) {
  if (files.length === 0) {
    return <p className="text-xs text-muted-foreground">ファイルがありません</p>;
  }
  return (
    <div className="flex flex-wrap gap-1.5">
      {files.map((fileName) => {
        const on = selected.includes(fileName);
        return (
          <button
            key={fileName}
            type="button"
            onClick={() =>
              onChange(
                on
                  ? selected.filter((f) => f !== fileName)
                  : [...selected, fileName],
              )
            }
            className={`rounded-md border px-2 py-0.5 font-mono text-xs ${
              on
                ? "border-primary bg-primary/10"
                : "border-input text-muted-foreground hover:bg-muted"
            }`}
          >
            {fileName}
          </button>
        );
      })}
    </div>
  );
}

function FileList({
  charaID,
  baseURL,
  files,
}: {
  charaID: string;
  baseURL: string;
  files: ResourceFile[];
}) {
  if (files.length === 0) {
    return <p className="text-xs text-muted-foreground">まだファイルがありません</p>;
  }
  return (
    <ul className="max-h-72 space-y-1 overflow-y-auto rounded-md border p-2">
      {files.map((file) => {
        const url = `${baseURL}/${charaID}/${file.fileName}`;
        return (
          <li key={file.fileName} className="flex items-center gap-3 text-xs">
            {hasExtension(file.fileName, imageExtensions) ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img src={url} alt="" className="h-10 w-10 rounded object-contain bg-muted" />
            ) : (
              <div className="h-10 w-10" />
            )}
            <a
              href={url}
              target="_blank"
              rel="noreferrer"
              className="flex-1 truncate font-mono hover:underline"
            >
              {file.fileName}
            </a>
            <span className="text-muted-foreground">{formatSize(file.size)}</span>
          </li>
        );
      })}
    </ul>
  );
}

/** キャラのリソース（画像・音声・VRM）のアップロードと、表情・アラームのボイスの編集 */
export function CharaResources({
  chara,
  onSaved,
}: {
  chara: Chara;
  onSaved: () => void;
}) {
  const { data, error, isLoading, mutate } = useSWR(
    `/chara/${chara.charaID}/files`,
    () => fetchResourceFiles(chara.charaID),
  );
  const files = data?.files ?? [];
  const fileNames = files.map((f) => f.fileName);
  const imageFiles = fileNames.filter((f) => hasExtension(f, imageExtensions));
  const voiceFiles = fileNames.filter((f) => hasExtension(f, voiceExtensions));

  const inputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [dragging, setDragging] = useState(false);
  const [expressions, setExpressions] = useState<[string, CharaExpression][]>(
    Object.entries(chara.expressions),
  );
  const [calls, setCalls] = useState<CharaCall[]>(chara.calls);
  const [saving, setSaving] = useState(false);

  const handleUpload = async (selected: FileList | null) => {
    if (!selected || selected.length === 0) return;
    setUploading(true);
    const uploaded: string[] = [];
    try {
      for (const file of Array.from(selected)) {
        await uploadResourceFile(chara.charaID, file);
        uploaded.push(file.name);
      }
      // 同じ名前で上書きしたものは CloudFront のキャッシュを消す
      const overwritten = uploaded.filter((name) => fileNames.includes(name));
      if (overwritten.length > 0) {
        await invalidateResourceFiles(chara.charaID, overwritten);
      }
      toast.success(`${uploaded.length}件アップロードしました`);
    } catch (err) {
      toast.error(errorMessage(err, "アップロードに失敗しました"));
    } finally {
      setUploading(false);
      if (inputRef.current) inputRef.current.value = "";
      mutate();
    }
  };

  const updateExpression = (index: number, patch: Partial<CharaExpression>) =>
    setExpressions((prev) =>
      prev.map(([name, e], i) => (i === index ? [name, { ...e, ...patch }] : [name, e])),
    );

  const handleSave = async () => {
    const names = expressions.map(([name]) => name.trim());
    if (new Set(names).size !== names.length) {
      toast.error("表情の名前が重なっています");
      return;
    }
    setSaving(true);
    try {
      await updateCharaAssets(chara.charaID, {
        expressions: Object.fromEntries(
          expressions.map(([name, e]) => [name.trim(), e]),
        ),
        calls,
      });
      toast.success("表情とアラームのボイスを保存しました");
      onSaved();
    } catch (err) {
      toast.error(errorMessage(err, "保存に失敗しました"));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4 text-sm">
      <Section title="ファイル">
        <p className="text-xs text-muted-foreground">
          png / jpg / caf / mp3 / m4a / wav / vrm。ファイル名は英数字と . _ - だけ。同じ名前なら上書きする
        </p>
        {/* ここにファイルをドラッグ＆ドロップするか、ボタンから選ぶ */}
        <div
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={(e) => {
            e.preventDefault();
            setDragging(false);
            if (!uploading) handleUpload(e.dataTransfer.files);
          }}
          className={`flex flex-col items-center gap-2 rounded-md border-2 border-dashed p-6 text-center transition-colors ${
            dragging ? "border-primary bg-primary/5" : "border-input"
          }`}
        >
          <p className="text-sm text-muted-foreground">
            {uploading ? "アップロード中..." : "ここにファイルをドラッグ＆ドロップ"}
          </p>
          <input
            ref={inputRef}
            type="file"
            multiple
            accept=".png,.jpg,.jpeg,.caf,.mp3,.m4a,.wav,.vrm"
            disabled={uploading}
            onChange={(e) => handleUpload(e.target.files)}
            className="text-xs file:mr-3 file:rounded-md file:border file:border-input file:bg-background file:px-3 file:py-1.5"
          />
        </div>
        {isLoading && <p className="text-xs text-muted-foreground">読み込み中...</p>}
        {error && <p className="text-xs text-destructive">ファイルを読めませんでした</p>}
        {data && (
          <FileList charaID={chara.charaID} baseURL={data.baseURL} files={files} />
        )}
      </Section>

      <Section title="表情（キャラ画面の立ち絵とタップのボイス）">
        {expressions.map(([name, expression], index) => (
          <div key={index} className="space-y-2 rounded-md border p-3">
            <div className="flex gap-2">
              <input
                className={`${inputClass} font-mono`}
                value={name}
                placeholder="normal"
                onChange={(e) =>
                  setExpressions((prev) =>
                    prev.map((entry, i) =>
                      i === index ? [e.target.value, entry[1]] : entry,
                    ),
                  )
                }
              />
              <Button
                type="button"
                variant="ghost"
                onClick={() =>
                  setExpressions((prev) => prev.filter((_, i) => i !== index))
                }
              >
                削除
              </Button>
            </div>
            <div className="space-y-1">
              <p className="text-xs font-medium">画像</p>
              <FilePicker
                files={imageFiles}
                selected={expression.imageFileNames}
                onChange={(imageFileNames) => updateExpression(index, { imageFileNames })}
              />
            </div>
            <div className="space-y-1">
              <p className="text-xs font-medium">ボイス</p>
              <FilePicker
                files={voiceFiles}
                selected={expression.voiceFileNames}
                onChange={(voiceFileNames) => updateExpression(index, { voiceFileNames })}
              />
            </div>
          </div>
        ))}
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() =>
            setExpressions((prev) => [
              ...prev,
              ["", { imageFileNames: [], voiceFileNames: [] }],
            ])
          }
        >
          表情を追加
        </Button>
      </Section>

      <Section title="アラームのボイス（電話をかけたときに流す）">
        {calls.map((call, index) => (
          <div key={index} className="grid gap-2 sm:grid-cols-[1fr_12rem_auto]">
            <input
              className={inputClass}
              value={call.message}
              placeholder="セリフ（アプリの表示用）"
              onChange={(e) =>
                setCalls((prev) =>
                  prev.map((c, i) => (i === index ? { ...c, message: e.target.value } : c)),
                )
              }
            />
            <select
              className={`${inputClass} font-mono`}
              value={call.voiceFileName}
              onChange={(e) =>
                setCalls((prev) =>
                  prev.map((c, i) =>
                    i === index ? { ...c, voiceFileName: e.target.value } : c,
                  ),
                )
              }
            >
              <option value="">ファイルを選ぶ</option>
              {voiceFiles.map((f) => (
                <option key={f} value={f}>
                  {f}
                </option>
              ))}
            </select>
            <Button
              type="button"
              variant="ghost"
              onClick={() => setCalls((prev) => prev.filter((_, i) => i !== index))}
            >
              削除
            </Button>
          </div>
        ))}
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() => setCalls((prev) => [...prev, { message: "", voiceFileName: "" }])}
        >
          ボイスを追加
        </Button>
      </Section>

      <div className="flex justify-end">
        <Button onClick={handleSave} disabled={saving}>
          {saving ? "保存中..." : "表情とボイスを保存"}
        </Button>
      </div>
    </div>
  );
}
