import SwiftUI

/// 通話画面で、こちらの声が届いていることを見せるマイクの表示。
/// 聞いているあいだだけ、声の大きさに合わせて棒が伸びる。キャラが話しているあいだは薄く出して、場所を空けておく
struct CallMicIndicator: View {
    let level: Float
    let isListening: Bool

    /// 棒ごとの伸びやすさ。真ん中ほどよく伸びる
    private static let barWeights: [CGFloat] = [0.5, 0.8, 1.0, 0.8, 0.5]
    private static let minBarHeight: CGFloat = 4
    private static let maxBarHeight: CGFloat = 20

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isListening ? "mic.fill" : "mic")
                .font(.subheadline.weight(.semibold))
            HStack(spacing: 3) {
                ForEach(Self.barWeights.indices, id: \.self) { index in
                    Capsule()
                        .frame(width: 4, height: barHeight(weight: Self.barWeights[index]))
                }
            }
            .frame(height: Self.maxBarHeight)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(isListening ? Color(.callGreen) : .black.opacity(0.35), in: Capsule())
        .opacity(isListening ? 1 : 0.5)
        .animation(.easeOut(duration: 0.12), value: level)
        .animation(.easeInOut(duration: 0.2), value: isListening)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: isListening ? "conversation-status-listening" : "conversation-status-speaking"))
    }

    private func barHeight(weight: CGFloat) -> CGFloat {
        guard isListening else { return Self.minBarHeight }
        let range = Self.maxBarHeight - Self.minBarHeight
        return Self.minBarHeight + range * CGFloat(level) * weight
    }
}
