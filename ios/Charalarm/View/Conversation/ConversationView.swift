import SwiftUI

/// ずんだもんとのリアルタイム音声会話画面。
/// standalone（DEBUG 動線）と CallKit 着信フローの両方から使う。
struct ConversationView: View {
    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss

    init(
        mode: ConversationMode = .standalone,
        textGenerationRepository: TextGenerationRepository = BackendTextGenerationRepository()
    ) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(
            mode: mode,
            textGenerationRepository: textGenerationRepository
        ))
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("ずんだもん")
                .font(.title2)
                .bold()

            Text(statusLabel)
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(viewModel.text)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Text(String(format: "%02d:%02d",
                        Int(viewModel.conversationDuration) / 60,
                        Int(viewModel.conversationDuration) % 60))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                viewModel.endButtonTapped()
            } label: {
                Text("通話を終了")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.teardown()
        }
        .onChange(of: viewModel.shouldDismiss) { _, shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }

    private var statusLabel: String {
        switch viewModel.status {
        case .idle: return "準備中…"
        case .initializingVoiceVox: return "VOICEVOX 初期化中…"
        case .requestingPermission: return "マイクの許可を確認中…"
        case .generatingScript: return "考え中…"
        case .synthesizingVoice: return "音声を準備中…"
        case .playingVoice: return "話しています…"
        case .recognizingSpeech: return "聞いています…"
        case .ended: return "通話終了"
        }
    }
}
