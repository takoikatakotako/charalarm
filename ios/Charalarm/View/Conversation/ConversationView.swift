import SwiftUI

/// キャラとのリアルタイム音声会話画面。
/// ホーム画面の電話ボタン（standalone）と CallKit 着信フローの両方から使う。
struct ConversationView: View {
    @State private var viewState: ConversationViewState
    @Environment(\.dismiss) private var dismiss
    @AppStorage(TopBackground.defaultsKey) private var selectedBackground = TopBackground.washitsu.rawValue
    private let topic: ConversationTopic

    init(
        charaID: String,
        mode: ConversationMode = .standalone,
        topic: ConversationTopic = .call,
        textGenerationRepository: TextGenerationRepository = BackendTextGenerationRepository()
    ) {
        self.topic = topic
        _viewState = State(initialValue: ConversationViewState(
            charaID: charaID,
            mode: mode,
            topic: topic,
            textGenerationRepository: textGenerationRepository
        ))
    }

    var body: some View {
        Group {
            if isTodaySchedule {
                TodayScheduleView(viewState: viewState)
            } else {
                callBody
            }
        }
        .onAppear {
            viewState.onAppear()
        }
        .onDisappear {
            viewState.teardown()
        }
        .onChange(of: viewState.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private var isTodaySchedule: Bool {
        if case .todaySchedule = topic { return true }
        return false
    }

    /// 電話・話題のときの画面。ビデオ通話のように、相手 (キャラ) の映像を画面いっぱいに出す
    private var callBody: some View {
        ZStack {
            callVideo

            // 上下を暗くして、名前と字幕を読みやすくする
            VStack(spacing: 0) {
                LinearGradient(colors: [.black.opacity(0.55), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 220)
                Spacer()
                LinearGradient(colors: [.clear, .black.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 320)
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 16) {
                callHeader
                Spacer()
                callCaption
                CallActionButton(kind: .decline, size: 68) {
                    viewState.endButtonTapped()
                }
                .accessibilityLabel(String(localized: "conversation-end"))
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
        }
    }

    /// 相手のカメラの映像: ホームと同じ背景の前にキャラ
    private var callVideo: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                Image(TopBackground.from(selectedBackground).image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                if let vrmModelFileURL = viewState.vrmModelFileURL {
                    CharaVRMView(charaID: viewState.charaID, modelFileURL: vrmModelFileURL, framing: .bust)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                } else if let charaImage = viewState.charaImage {
                    Image(uiImage: charaImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: proxy.size.width, height: proxy.size.height * 0.85, alignment: .bottom)
                }
            }
        }
        .ignoresSafeArea()
    }

    /// 左上に相手の名前・状態・通話時間、右上に自分の小窓
    private var callHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewState.charaName)
                    .font(.title2.weight(.semibold))
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(.callGreen))
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                    Text(String(format: "%02d:%02d",
                                Int(viewState.conversationDuration) / 60,
                                Int(viewState.conversationDuration) % 60))
                        .monospacedDigit()
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
            }
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.4), radius: 4)

            Spacer()

            selfPreview
        }
        .padding(.top, 8)
    }

    /// 自分の小窓。カメラは使わないので、聞いているあいだマイクを光らせる
    private var selfPreview: some View {
        let isListening = viewState.status == .recognizingSpeech
        return RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(.ultraThinMaterial)
            .frame(width: 84, height: 120)
            .overlay {
                Image(systemName: "person.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .overlay(alignment: .bottomTrailing) {
                Image(systemName: isListening ? "mic.fill" : "mic")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(isListening ? Color(.callGreen) : .black.opacity(0.4), in: Circle())
                    .padding(6)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isListening ? Color(.callGreen) : .white.opacity(0.3), lineWidth: isListening ? 2 : 1)
            }
            .animation(.easeInOut(duration: 0.2), value: isListening)
            .accessibilityHidden(true)
    }

    /// 字幕。話している言葉の最後のほうを出す
    @ViewBuilder
    private var callCaption: some View {
        if !viewState.text.isEmpty {
            Text(viewState.text)
                .font(.callout)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .truncationMode(.head)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var statusLabel: String {
        Self.statusLabel(viewState.status)
    }

    static func statusLabel(_ status: ConversationStatus) -> String {
        switch status {
        case .idle, .preparing: return String(localized: "conversation-status-preparing")
        case .requestingPermission: return String(localized: "conversation-status-permission")
        case .generatingScript: return String(localized: "conversation-status-thinking")
        case .synthesizingVoice: return String(localized: "conversation-status-voice")
        case .playingVoice: return String(localized: "conversation-status-speaking")
        case .recognizingSpeech: return String(localized: "conversation-status-listening")
        case .ended: return String(localized: "conversation-status-ended")
        }
    }
}
