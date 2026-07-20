import SwiftUI

/// ずんだもんとのリアルタイム音声会話画面（フェーズ2: アプリ内 simulated）。
struct ConversationView: View {
    @StateObject private var viewModel = ConversationViewModel()
    @Environment(\.dismiss) private var dismiss

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
                viewModel.requestDismiss()
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
