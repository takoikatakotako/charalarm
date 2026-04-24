"use client";

import Link from "next/link";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import type { User } from "@/lib/api/types";

interface UserTableProps {
  users: User[];
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

export function UserTable({ users }: UserTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>User ID</TableHead>
          <TableHead className="w-24">Platform</TableHead>
          <TableHead className="w-24">Premium</TableHead>
          <TableHead className="w-48">登録日</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {users.map((user) => (
          <TableRow key={user.userID}>
            <TableCell>
              <Link
                href={`/users/${user.userID}`}
                className="font-mono text-sm text-primary hover:underline"
              >
                {user.userID}
              </Link>
            </TableCell>
            <TableCell className="text-sm text-muted-foreground">
              {user.platform || "-"}
            </TableCell>
            <TableCell>
              {user.premiumPlan ? (
                <Badge>Premium</Badge>
              ) : (
                <span className="text-sm text-muted-foreground">-</span>
              )}
            </TableCell>
            <TableCell className="text-sm text-muted-foreground">
              {formatDate(user.createdAt)}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
