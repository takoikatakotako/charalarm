import SwiftUI

/// キャラとのリアルタイム音声会話画面。
/// ホーム画面の電話ボタン（standalone）と CallKit 着信フローの両方から使う。
struct ConversationView: View {
    @State private var viewState: ConversationViewState
    @Environment(\.dismiss) private var dismiss
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

    /// 電話・話題のときの画面
    private var callBody: some View {
        ZStack {
            CallBackground()

            VStack(spacing: 16) {
                if let vrmModelFileURL = viewState.vrmModelFileURL {
                    // 話している相手を胸から上で出す
                    CharaVRMView(charaID: viewState.charaID, modelFileURL: vrmModelFileURL, framing: .bust)
                        .frame(maxWidth: .infinity)
                        .frame(maxHeight: 360)
                } else {
                    Spacer()
                }

                CallerNameText(name: viewState.charaName, status: statusLabel)

                ScrollView {
                    Text(viewState.text)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 24)
                }
                .foregroundStyle(.white.opacity(0.9))

                Text(String(format: "%02d:%02d",
                            Int(viewState.conversationDuration) / 60,
                            Int(viewState.conversationDuration) % 60))
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.7))

                CallActionButton(kind: .decline) {
                    viewState.endButtonTapped()
                }
                .accessibilityLabel(String(localized: "conversation-end"))
                .padding(.bottom, 32)
            }
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
