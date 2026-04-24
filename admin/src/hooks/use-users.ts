import useSWR from "swr";
import {
  fetchUsers,
  fetchUser,
  fetchUserAlarms,
} from "@/lib/api/users";
import type {
  UsersResponse,
  User,
  UserAlarmsResponse,
} from "@/lib/api/types";

export function useUsers(limit: number, cursor: string | null) {
  return useSWR<UsersResponse>(
    [`/users`, limit, cursor],
    () => fetchUsers(limit, cursor),
  );
}

export function useUser(userID: string | null) {
  return useSWR<User>(userID ? `/users/${userID}` : null, () =>
    fetchUser(userID!),
  );
}

export function useUserAlarms(userID: string | null) {
  return useSWR<UserAlarmsResponse>(
    userID ? `/users/${userID}/alarms` : null,
    () => fetchUserAlarms(userID!),
  );
}
