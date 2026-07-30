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
  registeredIPAddress: string;
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
