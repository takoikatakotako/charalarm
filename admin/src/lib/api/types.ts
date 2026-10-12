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

export interface CharaCreate extends CharaSettings {
  charaID: string;
}

export interface CharaListResponse {
  charas: Chara[];
}
