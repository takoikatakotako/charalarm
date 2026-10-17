export interface IOSPlatformInfo {
  pushToken: string;
  pushTokenSNSEndpoint: string;
  voIPPushToken: string;
  voIPPushTokenSNSEndpoint: string;
}

export interface User {
  userID: string;
  platform: string;
  premiumPlan: boolean;
  createdAt: string;
  updatedAt: string;
  iosPlatformInfo: IOSPlatformInfo;
}

export interface UsersResponse {
  users: User[];
  nextCursor?: string;
}

export interface Alarm {
  alarmID: string;
  userID: string;
  type: string;
  target: string;
  enable: boolean;
  name: string;
  hour: number;
  minute: number;
  timeDifference: number;
  charaID: string;
  charaName: string;
  voiceFileName: string;
  sunday: boolean;
  monday: boolean;
  tuesday: boolean;
  wednesday: boolean;
  thursday: boolean;
  friday: boolean;
  saturday: boolean;
}

export interface UserAlarmsResponse {
  alarms: Alarm[];
}

export interface News {
  newsId: string;
  title: string;
  body: string;
  registeredAt: string;
}

export interface NewsListResponse {
  news: News[];
}

export interface CharaProfile {
  title: string;
  name: string;
  url: string;
}

export interface CharaCall {
  message: string;
  voiceFileName: string;
}

export interface CharaExpression {
  imageFileNames: string[];
  voiceFileNames: string[];
}

/** 見た目のタイプ。illustration: 表情ごとの立ち絵 / vrm: 3D モデル */
export type AppearanceType = "illustration" | "vrm";

/** 会話のタイプ。none: アラーム専用 / voicevox: 端末内の VOICEVOX / gemini: サーバの Gemini TTS */
export type ConversationType = "none" | "voicevox" | "gemini";

/** 管理画面で編集する項目。キャラの追加と編集で同じ形 */
export interface CharaSettings {
  enable: boolean;
  name: string;
  description: string;
  profiles: CharaProfile[];
  displayOrder: number;
  appearanceType: AppearanceType;
  vrmFileName: string;
  conversationType: ConversationType;
  conversationPrompt: string;
  voicevoxStyleID: number;
  /** 会話できる言語（"ja" / "en"）。先頭が第一言語 */
  conversationLanguages: string[];
  geminiVoice: string;
  geminiVoiceStyle: string;
  /** 通話の場面のプロンプト。空ならサーバの既定 */
  callOpeningPrompt: string;
  callEndingPrompt: string;
  callNoInputEndingPrompt: string;
}

export interface Chara extends CharaSettings {
  charaID: string;
  createdAt: string;
  updatedAt: string;
  calls: CharaCall[];
  expressions: Record<string, CharaExpression>;
}

/** 会話・タップのセリフに使える言語（BCP 47） */
export const LANGUAGES = [
  { value: "ja", label: "日本語" },
  { value: "en", label: "英語（English）" },
  { value: "zh-Hans", label: "中国語・簡体字（简体中文）" },
  { value: "zh-Hant", label: "中国語・繁体字（繁體中文）" },
  { value: "ko", label: "韓国語（한국어）" },
  { value: "es", label: "スペイン語（Español）" },
  { value: "fr", label: "フランス語（Français）" },
  { value: "de", label: "ドイツ語（Deutsch）" },
] as const;

export function languageLabel(value: string): string {
  return LANGUAGES.find((l) => l.value === value)?.label ?? value;
}

/** タップのセリフを流す条件。空の項目は条件にしない */
export interface TapLineWhen {
  /** 日付（"MM-DD"） */
  dates: string[];
  /** 時間帯 [開始, 終了)。開始 > 終了なら日をまたぐ */
  hours: number[];
  /** 曜日（0 = 日曜） */
  weekdays: number[];
}

/** トップでキャラをタップしたときのセリフ */
export interface TapLine {
  /** 保存する前の案は空（サーバが付ける） */
  id: string;
  /** セリフの言語（LANGUAGES のどれか） */
  language: string;
  text: string;
  /** ボイスのファイル名。まだなら空 */
  voiceFileName: string;
  theme: string;
  when: TapLineWhen;
}

export interface TapLineTheme {
  key: string;
  label: string;
  when: TapLineWhen;
}

export interface CharaCreate extends CharaSettings {
  charaID: string;
}

export interface CharaListResponse {
  charas: Chara[];
}

/** キャラのリソース（S3 の {charaID}/ にあるファイル） */
export interface ResourceFile {
  fileName: string;
  size: number;
  lastModified: string;
}

export interface ResourceFileListResponse {
  /** {baseURL}/{charaID}/{fileName} でファイルを取れる */
  baseURL: string;
  files: ResourceFile[];
}

export interface UploadURLResponse {
  uploadURL: string;
  /** PUT に付ける Content-Type（署名に含まれる） */
  contentType: string;
}

export interface CharaAssets {
  expressions: Record<string, CharaExpression>;
  calls: CharaCall[];
}
