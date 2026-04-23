"use client";

import Link from "next/link";
import { ChevronLeft } from "lucide-react";
import { useUser } from "@/hooks/use-users";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { UserAlarms } from "@/components/users/user-alarms";

interface UserDetailProps {
  userID: string;
}

function formatDate(value: string): string {
  if (!value) return "-";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("ja-JP", {
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function UserDetail({ userID }: UserDetailProps) {
  const { data, error, isLoading } = useUser(userID);

  if (isLoading) return <p className="text-muted-foreground">読み込み中...</p>;
  if (error) return <p className="text-destructive">エラーが発生しました</p>;
  if (!data) return null;

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-2">
        <Link
          href="/users"
          className="inline-flex items-center text-sm text-muted-foreground hover:text-foreground"
        >
          <ChevronLeft className="h-4 w-4" />
          ユーザー一覧
        </Link>
      </div>

      <h1 className="text-2xl font-bold">ユーザー詳細</h1>

      <Card>
        <CardHeader>
          <CardTitle>基本情報</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-[160px_1fr] gap-2 text-sm">
            <span className="text-muted-foreground">User ID</span>
            <span className="font-mono break-all">{data.userID}</span>
            <span className="text-muted-foreground">Platform</span>
            <span>{data.platform || "-"}</span>
            <span className="text-muted-foreground">Premium</span>
            <span>
              {data.premiumPlan ? (
                <Badge>Premium</Badge>
              ) : (
                <span className="text-muted-foreground">-</span>
              )}
            </span>
            <span className="text-muted-foreground">登録日</span>
            <span>{formatDate(data.createdAt)}</span>
            <span className="text-muted-foreground">更新日</span>
            <span>{formatDate(data.updatedAt)}</span>
            <span className="text-muted-foreground">登録時 IP</span>
            <span className="font-mono">{data.registeredIPAddress || "-"}</span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>iOS Push Token</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-[200px_1fr] gap-2 text-sm">
            <span className="text-muted-foreground">Push Token</span>
            <span className="font-mono break-all">
              {data.iosPlatformInfo.pushToken || "-"}
            </span>
            <span className="text-muted-foreground">Push SNS Endpoint</span>
            <span className="font-mono break-all">
              {data.iosPlatformInfo.pushTokenSNSEndpoint || "-"}
            </span>
            <span className="text-muted-foreground">VoIP Push Token</span>
            <span className="font-mono break-all">
              {data.iosPlatformInfo.voIPPushToken || "-"}
            </span>
            <span className="text-muted-foreground">VoIP SNS Endpoint</span>
            <span className="font-mono break-all">
              {data.iosPlatformInfo.voIPPushTokenSNSEndpoint || "-"}
            </span>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>アラーム一覧</CardTitle>
        </CardHeader>
        <CardContent>
          <UserAlarms userID={userID} />
        </CardContent>
      </Card>
    </div>
  );
}
