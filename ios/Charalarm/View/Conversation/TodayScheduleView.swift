import SwiftUI

/// 「今日の予定」の画面。今日の時間割を大きく出し、右下でキャラが読み上げる
struct TodayScheduleView: View {
    let viewState: ConversationViewState
    @State private var showingCalendarSelection = false

    var body: some View {
        VStack(spacing: 0) {
            header

            if let events = viewState.todayEvents {
                TodayTimelineView(events: events)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(.systemBackground))
        // キャラは画面の下の端まで。話していることとボタンは、キャラの左に（キャラは動かさない）
        .overlay(alignment: .bottomTrailing) {
            charaView
                .frame(width: 150, height: 230)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .bottom)
        }
        .overlay(alignment: .bottomLeading) {
            speechPanel
        }
        .onAppear {
            // キャラの準備を待たずに、予定は先に出す
            if viewState.todayEvents == nil {
                viewState.reloadTodayEvents()
            }
        }
        .sheet(isPresented: $showingCalendarSelection, onDismiss: {
            viewState.reloadTodayEvents()
        }) {
            NavigationStack {
                CalendarSelectionView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(String(localized: "common-close")) {
                                showingCalendarSelection = false
                            }
                        }
                    }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "today-schedule-title"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brand)
                Text(Date.now.formatted(.dateTime.month().day().weekday(.wide)))
                    .font(.title2.bold())
            }
            Spacer()
            Button {
                showingCalendarSelection = true
            } label: {
                Image(systemName: "calendar.badge.checkmark")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel(String(localized: "calendar-selection-title"))
            Button {
                viewState.endButtonTapped()
            } label: {
                Image(systemName: "xmark")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(.secondarySystemBackground), in: Circle())
            }
            .accessibilityLabel(String(localized: "common-close"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    /// キャラの左に出す、話していることと再生・停止ボタン
    private var speechPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !viewState.text.isEmpty {
                Text(viewState.text)
                    .font(.callout)
                    .lineLimit(5)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
            }
            HStack(spacing: 10) {
                playStopButton
                if !viewState.isStopped {
                    Text(ConversationView.statusLabel(viewState.status))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: Capsule())
                }
            }
        }
        .padding(.leading, 16)
        // キャラの幅だけ右を空ける
        .padding(.trailing, 150)
        .padding(.bottom, 8)
    }

    /// 話しているあいだは停止、止まっていれば再生（もう一度読んでもらう）
    private var playStopButton: some View {
        Button {
            if viewState.isStopped {
                viewState.replayTodaySchedule()
            } else {
                viewState.stopSpeaking()
            }
        } label: {
            Image(systemName: viewState.isStopped ? "play.fill" : "stop.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Color.brand, in: Circle())
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
        .accessibilityLabel(viewState.isStopped ? String(localized: "today-schedule-replay") : String(localized: "today-schedule-stop"))
    }

    @ViewBuilder
    private var charaView: some View {
        if let vrmModelFileURL = viewState.vrmModelFileURL {
            CharaVRMView(charaID: viewState.charaID, modelFileURL: vrmModelFileURL, framing: .bust, expression: viewState.expression)
        } else if let charaImage = viewState.charaImage {
            // 立ち絵は全身なので、上のほう（顔から胸）を出す
            Image(uiImage: charaImage)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 230 * 2, alignment: .top)
                .frame(width: 150, height: 230, alignment: .top)
                .clipped()
        }
    }
}

/// 1日の時間割。時刻の目盛りに予定を並べ、今の時刻に線を引く
struct TodayTimelineView: View {
    let events: [TodayEvent]

    private let hourHeight: CGFloat = 56
    private let labelWidth: CGFloat = 48
    /// 右下のキャラに最後の予定が隠れないよう、下に空けておく
    private let bottomSpace: CGFloat = 200

    var body: some View {
        let allDayEvents = events.filter(\.isAllDay)
        let timedEvents = events.filter { !$0.isAllDay }

        VStack(spacing: 0) {
            if !allDayEvents.isEmpty {
                allDaySection(allDayEvents)
            }
            if events.isEmpty {
                Text(String(localized: "today-schedule-empty"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            }
            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    TimelineView(.everyMinute) { context in
                        grid(timedEvents: timedEvents, now: context.date)
                    }
                    .padding(.bottom, bottomSpace)
                }
                .onAppear {
                    proxy.scrollTo(firstVisibleHour(timedEvents: timedEvents), anchor: .top)
                }
            }
        }
    }

    private func allDaySection(_ allDayEvents: [TodayEvent]) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(String(localized: "today-schedule-all-day"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: labelWidth, alignment: .trailing)
                .padding(.top, 6)
            VStack(spacing: 4) {
                ForEach(allDayEvents) { event in
                    EventBlock(event: event, showsTime: false)
                        .frame(height: 26)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func grid(timedEvents: [TodayEvent], now: Date) -> some View {
        let dayStart = Calendar.current.startOfDay(for: now)
        return ZStack(alignment: .topLeading) {
            // 時刻の目盛り
            VStack(spacing: 0) {
                ForEach(0..<24, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 8) {
                        Text(hourLabel(hour, dayStart: dayStart))
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: labelWidth, alignment: .trailing)
                            .offset(y: -6)
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 0.5)
                    }
                    .frame(height: hourHeight, alignment: .top)
                    .id(hour)
                }
            }

            // 予定
            GeometryReader { geometry in
                let columnsWidth = geometry.size.width - labelWidth - 8
                ForEach(layout(timedEvents, dayStart: dayStart)) { item in
                    let width = columnsWidth / CGFloat(item.columnCount)
                    EventBlock(event: item.event, showsTime: item.height >= 40)
                        .frame(width: width - 2, height: item.height)
                        .offset(x: labelWidth + 8 + width * CGFloat(item.column), y: item.top)
                }
            }

            // 今の時刻
            nowLine(now: now, dayStart: dayStart)
        }
        .frame(height: hourHeight * 24)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func nowLine(now: Date, dayStart: Date) -> some View {
        HStack(spacing: 0) {
            Circle()
                .fill(Color.red)
                .frame(width: 8, height: 8)
            Rectangle()
                .fill(Color.red)
                .frame(height: 1.5)
        }
        .padding(.leading, labelWidth + 4)
        .offset(y: y(of: now, dayStart: dayStart) - 4)
        .accessibilityHidden(true)
    }

    private func hourLabel(_ hour: Int, dayStart: Date) -> String {
        let date = Calendar.current.date(byAdding: .hour, value: hour, to: dayStart) ?? dayStart
        return date.formatted(.dateTime.hour())
    }

    private func y(of date: Date, dayStart: Date) -> CGFloat {
        let minutes = min(max(date.timeIntervalSince(dayStart) / 60, 0), 24 * 60)
        return CGFloat(minutes / 60) * hourHeight
    }

    /// はじめに見せる時刻。最初の予定か今の少し前
    private func firstVisibleHour(timedEvents: [TodayEvent]) -> Int {
        let calendar = Calendar.current
        let nowHour = calendar.component(.hour, from: .now)
        let firstEventHour = timedEvents.first.map { calendar.component(.hour, from: $0.start) } ?? nowHour
        return max(min(firstEventHour, nowHour) - 1, 0)
    }

    /// 重なる予定を横に並べる
    private func layout(_ events: [TodayEvent], dayStart: Date) -> [TimelineItem] {
        var items: [TimelineItem] = []
        var cluster: [TimelineItem] = []
        var clusterEnd = Date.distantPast
        var columnEnds: [Date] = []

        func flush() {
            let count = max(columnEnds.count, 1)
            items += cluster.map { item in
                var item = item
                item.columnCount = count
                return item
            }
            cluster = []
            columnEnds = []
        }

        for event in events.sorted(by: { $0.start < $1.start }) {
            if event.start >= clusterEnd {
                flush()
            }
            let column = columnEnds.firstIndex { $0 <= event.start } ?? columnEnds.count
            if column == columnEnds.count {
                columnEnds.append(event.end)
            } else {
                columnEnds[column] = event.end
            }
            clusterEnd = max(clusterEnd, event.end)
            let top = y(of: event.start, dayStart: dayStart)
            let height = max(y(of: event.end, dayStart: dayStart) - top, 22)
            cluster.append(TimelineItem(event: event, top: top, height: height, column: column, columnCount: 1))
        }
        flush()
        return items
    }
}

private struct TimelineItem: Identifiable {
    let event: TodayEvent
    let top: CGFloat
    let height: CGFloat
    let column: Int
    var columnCount: Int

    var id: String { event.id }
}

/// 時間割の予定ひとつ。カレンダーの色で塗る
private struct EventBlock: View {
    let event: TodayEvent
    let showsTime: Bool

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(event.calendarColor)
                .frame(width: 3)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                if showsTime {
                    Text(timeText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(event.calendarColor.opacity(0.18), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(timeText) \(event.title)")
    }

    private var timeText: String {
        if event.isAllDay {
            return String(localized: "today-schedule-all-day")
        }
        let format = Date.FormatStyle(date: .omitted, time: .shortened)
        return "\(event.start.formatted(format))–\(event.end.formatted(format))"
    }
}

#Preview {
    let start = Calendar.current.startOfDay(for: .now)
    TodayTimelineView(events: [
        TodayEvent(id: "a", title: "誕生日", start: start, end: start, isAllDay: true, calendarTitle: "家族", calendarColor: .orange),
        TodayEvent(id: "b", title: "定例ミーティング", start: start.addingTimeInterval(9 * 3600), end: start.addingTimeInterval(10 * 3600),
                   isAllDay: false, calendarTitle: "仕事", calendarColor: .blue),
        TodayEvent(id: "c", title: "1on1", start: start.addingTimeInterval(9.5 * 3600), end: start.addingTimeInterval(10.5 * 3600),
                   isAllDay: false, calendarTitle: "仕事", calendarColor: .green),
        TodayEvent(id: "d", title: "ランチ", start: start.addingTimeInterval(12 * 3600), end: start.addingTimeInterval(13 * 3600),
                   isAllDay: false, calendarTitle: "家族", calendarColor: .orange)
    ])
}
