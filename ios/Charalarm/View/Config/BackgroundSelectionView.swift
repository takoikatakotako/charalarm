import SwiftUI

struct BackgroundSelectionView: View {
    @AppStorage(TopBackground.defaultsKey) private var selectedBackground = TopBackground.washitsu.rawValue

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(TopBackground.allCases) { background in
                    Button {
                        selectedBackground = background.rawValue
                    } label: {
                        VStack(spacing: 8) {
                            Image(background.image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 190)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .accessibilityHidden(true)

                            HStack(spacing: 4) {
                                Text(background.title)
                                Spacer(minLength: 0)
                                if TopBackground.from(selectedBackground) == background {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand)
                                        .accessibilityHidden(true)
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(TopBackground.from(selectedBackground) == background ? Color.brand : .clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(TopBackground.from(selectedBackground) == background ? .isSelected : [])
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "config-background"))
    }
}
