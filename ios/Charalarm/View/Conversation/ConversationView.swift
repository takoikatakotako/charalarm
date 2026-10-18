import SwiftUI

/// キャラとのリアルタイム音声会話画面。
/// ホーム画面の電話ボタン（standalone）と CallKit 着信フローの両方から使う。
struct ConversationView: View {
    @State private var viewState: ConversationViewState
    @Environment(\.dismiss) private var dismiss

    init(
        charaID: String,
        mode: ConversationMode = .standalone,
        topic: ConversationTopic = .call,
        textGenerationRepository: TextGenerationRepository = BackendTextGenerationRepository()
    ) {
        _viewState = State(initialValue: ConversationViewState(
            charaID: charaID,
            mode: mode,
            topic: topic,
            textGenerationRepository: textGenerationRepository
        ))
    }

    var body: some View {
        VStack(spacing: 24) {
            if let vrmModelFileURL = viewState.vrmModelFileURL {
                // 話している相手を胸から上で出す
                CharaVRMView(charaID: viewState.charaID, modelFileURL: vrmModelFileURL, framing: .bust)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: 360)
            } else {
                Spacer()
            }

            Text(viewState.charaName)
                .font(.title2)
                .bold()

            Text(statusLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(viewState.text)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Text(String(format: "%02d:%02d",
                        Int(viewState.conversationDuration) / 60,
                        Int(viewState.conversationDuration) % 60))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                viewState.endButtonTapped()
            } label: {
                Text("通話を終了")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
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

    private var statusLabel: String {
        switch viewState.status {
        case .idle: return "準備中…"
        case .preparing: return "準備中…"
        case .requestingPermission: return "マイクの許可を確認中…"
        case .generatingScript: return "考え中…"
        case .synthesizingVoice: return "音声を準備中…"
        case .playingVoice: return "話しています…"
        case .recognizingSpeech: return "聞いています…"
        case .ended: return "通話終了"
        }
    }
}
