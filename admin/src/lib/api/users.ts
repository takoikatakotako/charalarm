import { apiGet } from "@/lib/api/client";
import type { UsersResponse, User, UserAlarmsResponse } from "@/lib/api/types";

export async function fetchUsers(
  limit: number,
  cursor: string | null,
): Promise<UsersResponse> {
  const params = new URLSearchParams({ limit: String(limit) });
  if (cursor) params.set("cursor", cursor);
  return apiGet<UsersResponse>(`/users?${params.toString()}`);
}

export async function fetchUser(userID: string): Promise<User> {
  return apiGet<User>(`/users/${encodeURIComponent(userID)}`);
}

export async function fetchUserAlarms(
  userID: string,
): Promise<UserAlarmsResponse> {
  return apiGet<UserAlarmsResponse>(
    `/users/${encodeURIComponent(userID)}/alarms`,
  );
}
