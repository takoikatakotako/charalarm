import SwiftUI

/// アプリの色と部品の見た目。色は場所ごとに決め打ちせず、ここかシステムの色（.primary・.secondary・グループの背景など）を使う。
extension Color {
    /// キャラームの緑（ボタン・スイッチ・強調）。アプリ全体の強調の色（AccentColor）と同じ。ダークモードでは少し明るい
    static let brand = Color(.accent)
    /// 消すなど、取り消せない操作
    static let destructive = Color(.charalarmDefaultPink)
}

extension ShapeStyle where Self == Color {
    static var brand: Color { Color.brand }
}

/// 画面の下に置く大きなボタン（次へ・保存など）
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(Color.brand.opacity(isEnabled ? 1 : 0.4), in: Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1)
            .contentShape(Capsule())
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

/// 広告。リストや画面の下の端に重ならないよう、safeAreaInset で下に置く
struct BannerAdInset: ViewModifier {
    let isShowing: Bool
    let adUnitID: String

    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom, spacing: 0) {
            if isShowing {
                AdmobBannerView(adUnitID: adUnitID)
                    .padding(.vertical, 4)
                    .frame(maxWidth: .infinity)
                    .background(.bar)
            }
        }
    }
}

extension View {
    func bannerAd(isShowing: Bool, adUnitID: String) -> some View {
        modifier(BannerAdInset(isShowing: isShowing, adUnitID: adUnitID))
    }
}
