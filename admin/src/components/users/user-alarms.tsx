"use client";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { useUserAlarms } from "@/hooks/use-users";
import type { Alarm } from "@/lib/api/types";

interface UserAlarmsProps {
  userID: string;
}

const WEEKDAY_LABELS: { key: keyof Alarm; label: string }[] = [
  { key: "sunday", label: "日" },
  { key: "monday", label: "月" },
  { key: "tuesday", label: "火" },
  { key: "wednesday", label: "水" },
  { key: "thursday", label: "木" },
  { key: "friday", label: "金" },
  { key: "saturday", label: "土" },
];

function formatTime(hour: number, minute: number): string {
  return `${String(hour).padStart(2, "0")}:${String(minute).padStart(2, "0")}`;
}

function formatWeekdays(alarm: Alarm): string {
  const days = WEEKDAY_LABELS.filter((w) => alarm[w.key]).map((w) => w.label);
  return days.length === 0 ? "-" : days.join(" ");
}

export function UserAlarms({ userID }: UserAlarmsProps) {
  const { data, error, isLoading } = useUserAlarms(userID);

  if (isLoading)
    return <p className="text-sm text-muted-foreground">読み込み中...</p>;
  if (error)
    return <p className="text-sm text-destructive">エラーが発生しました</p>;
  if (!data) return null;

  if (data.alarms.length === 0) {
    return (
      <p className="text-sm text-muted-foreground">アラームがありません</p>
    );
  }

  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead className="w-20">有効</TableHead>
          <TableHead className="w-24">時刻</TableHead>
          <TableHead>アラーム名</TableHead>
          <TableHead>キャラ</TableHead>
          <TableHead>曜日</TableHead>
          <TableHead className="w-32">タイプ</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {data.alarms.map((alarm) => (
          <TableRow key={alarm.alarmID}>
            <TableCell>
              {alarm.enable ? (
                <Badge>ON</Badge>
              ) : (
                <Badge variant="secondary">OFF</Badge>
              )}
            </TableCell>
            <TableCell className="font-mono">
              {formatTime(alarm.hour, alarm.minute)}
            </TableCell>
            <TableCell>{alarm.name || "-"}</TableCell>
            <TableCell className="text-sm text-muted-foreground">
              {alarm.charaName || alarm.charaID || "-"}
            </TableCell>
            <TableCell className="text-sm">{formatWeekdays(alarm)}</TableCell>
            <TableCell className="text-xs text-muted-foreground">
              {alarm.type}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
