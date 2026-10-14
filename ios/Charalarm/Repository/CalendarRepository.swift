import EventKit
import Foundation

/// 端末のカレンダー（EventKit）。会話で「今日の予定」を読むのに使う。
/// 送るのはタイトルと時刻だけ（場所・参加者・メモは読まない）。
struct CalendarRepository {
    private static let eventStore = EKEventStore()
    /// 送る予定の数の上限（/chat の道具の結果は 2,000 字まで）
    private static let maxEvents = 20

    /// 予定を読める（ユーザーがすべての予定へのアクセスを許可している）
    var isAuthorized: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    /// カレンダーへのアクセスを求める。許可されれば true
    func requestAccess() async -> Bool {
        do {
            return try await Self.eventStore.requestFullAccessToEvents()
        } catch {
            CharalarmLogger.error("Failed to request calendar access", error: error)
            return false
        }
    }

    /// 今日の予定を /chat の道具の結果（JSON）にする
    func todayEventsJSON(now: Date = Date(), calendar: Calendar = .current) -> String {
        guard isAuthorized else {
            return #"{"error":"カレンダーを読む許可がありません"}"#
        }
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return "[]"
        }
        let predicate = Self.eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let events = Self.eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(Self.maxEvents)
            .map { event in
                CalendarEventEntity(
                    title: String((event.title ?? "").prefix(50)),
                    start: event.isAllDay ? nil : formatter.string(from: event.startDate),
                    end: event.isAllDay ? nil : formatter.string(from: event.endDate),
                    allDay: event.isAllDay
                )
            }
        guard let data = try? JSONEncoder().encode(Array(events)), let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

/// /chat に送る予定。タイトルと時刻だけ
struct CalendarEventEntity: Encodable {
    let title: String
    let start: String?
    let end: String?
    let allDay: Bool
}
