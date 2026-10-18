import SwiftUI
import SDWebImageSwiftUI

protocol AlarmDetailCharaSelectorDelegate {
    func setRandomChara()
    func showVoiceList(chara: Chara)
}

/// アラームで電話をかけてくるキャラを選ぶ（先頭はランダム）
struct AlarmDetailCharaSelector: View {
    var delegate: AlarmDetailCharaSelectorDelegate
    @Binding var selectedChara: Chara?
    @Binding var charas: [Chara]

    private let size: CGFloat = 60

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Button {
                    delegate.setRandomChara()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: size, height: size)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(selectionRing(isSelected: selectedChara == nil))
                }
                .accessibilityLabel(String(localized: "alarm-random-chara"))

                if charas.isEmpty {
                    ProgressView()
                        .frame(width: size, height: size)
                }

                ForEach(charas) { chara in
                    Button {
                        delegate.showVoiceList(chara: chara)
                    } label: {
                        WebImage(url: URL(string: chara.thumbnailUrlString)) { image in
                            image.resizable()
                        } placeholder: {
                            Image(.characterPlaceholder).resizable()
                        }
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(selectionRing(isSelected: selectedChara?.charaID == chara.charaID))
                    }
                    .accessibilityLabel(chara.name)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    private func selectionRing(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .strokeBorder(Color.brand, lineWidth: isSelected ? 3 : 0)
    }
}
