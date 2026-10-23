import EventKit
import SwiftUI

/// 端末のカレンダー（EventKit）。会話で「今日の予定」を読むのに使う。
/// 送るのはタイトルと時刻だけ（場所・参加者・メモは読まない）。
struct CalendarRepository {
    private static let eventStore = EKEventStore()
    /// 送る予定の数の上限（/chat の道具の結果は 2,000 字まで）
    private static let maxEvents = 20

    private let userDefaultsRepository = UserDefaultsRepository()

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

    // MARK: - 使うカレンダー

    /// 端末のカレンダーを、アカウント（iCloud・Google など）ごとに分けて返す。選んでいるかも付ける
    func calendarGroups() -> [CalendarGroup] {
        guard isAuthorized else { return [] }
        let excluded = excludedCalendarIDs()
        let grouped = Dictionary(grouping: Self.eventStore.calendars(for: .event)) { $0.source.title }
        return grouped
            .map { sourceTitle, calendars in
                CalendarGroup(
                    id: sourceTitle,
                    title: sourceTitle,
                    calendars: calendars
                        .map { calendar in
                            SelectableCalendar(
                                id: calendar.calendarIdentifier,
                                title: calendar.title,
                                color: Color(cgColor: calendar.cgColor),
                                isSelected: !excluded.contains(calendar.calendarIdentifier)
                            )
                        }
                        .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
                )
            }
            .sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
    }

    /// カレンダーを使うかどうかを変える
    func setCalendar(id: String, isSelected: Bool) {
        var excluded = excludedCalendarIDs()
        if isSelected {
            excluded.remove(id)
        } else {
            excluded.insert(id)
        }
        userDefaultsRepository.setExcludedCalendarIDs(excluded)
    }

    /// 使わないカレンダー。まだ選んだことがなければ、誕生日と照会しているだけのカレンダー（祝日など）は使わない
    private func excludedCalendarIDs() -> Set<String> {
        if let excluded = userDefaultsRepository.getExcludedCalendarIDs() {
            return excluded
        }
        return Set(
            Self.eventStore.calendars(for: .event)
                .filter { $0.type == .birthday || $0.type == .subscription }
                .map(\.calendarIdentifier)
        )
    }

    private func selectedCalendars() -> [EKCalendar] {
        let excluded = excludedCalendarIDs()
        return Self.eventStore.calendars(for: .event).filter { !excluded.contains($0.calendarIdentifier) }
    }

    // MARK: - 今日の予定

    /// 使うカレンダーの今日の予定（時刻の早い順）。画面に出すのにも、/chat に送るのにも使う
    func todayEvents(now: Date = Date(), calendar: Calendar = .current) -> [TodayEvent] {
        guard isAuthorized else { return [] }
        let calendars = selectedCalendars()
        // 空の配列を渡すと全部のカレンダーを読んでしまうので、何も選んでいなければ予定なし
        guard !calendars.isEmpty else { return [] }
        let start = calendar.startOfDay(for: now)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return []
        }
        let predicate = Self.eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        return Self.eventStore.events(matching: predicate)
            .sorted { $0.startDate < $1.startDate }
            .prefix(Self.maxEvents)
            .map { event in
                TodayEvent(
                    id: event.calendarItemIdentifier + "\(event.startDate.timeIntervalSince1970)",
                    title: String((event.title ?? "").prefix(50)),
                    start: event.startDate,
                    end: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar.title,
                    calendarColor: Color(cgColor: event.calendar.cgColor)
                )
            }
    }

    /// 今日の予定を /chat の道具の結果（JSON）にする
    func todayEventsJSON(now: Date = Date(), calendar: Calendar = .current) -> String {
        guard isAuthorized else {
            return #"{"error":"カレンダーを読む許可がありません"}"#
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let events = todayEvents(now: now, calendar: calendar).map { event in
            CalendarEventEntity(
                title: event.title,
                start: event.isAllDay ? nil : formatter.string(from: event.start),
                end: event.isAllDay ? nil : formatter.string(from: event.end),
                allDay: event.isAllDay
            )
        }
        guard let data = try? JSONEncoder().encode(events), let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }
}

/// アカウントごとのカレンダー
struct CalendarGroup: Identifiable {
    let id: String
    let title: String
    let calendars: [SelectableCalendar]
}

/// 使うかどうかを選べるカレンダー
struct SelectableCalendar: Identifiable {
    let id: String
    let title: String
    let color: Color
    let isSelected: Bool
}

/// 画面に出す今日の予定。端末の中だけで使う（カレンダーの名前や色はサーバに送らない）
struct TodayEvent: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: Color
}

/// /chat に送る予定。タイトルと時刻だけ
struct CalendarEventEntity: Encodable {
    let title: String
    let start: String?
    let end: String?
    let allDay: Bool
}
