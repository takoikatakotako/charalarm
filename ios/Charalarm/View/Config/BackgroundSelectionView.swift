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
                            Image(background.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 190)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            HStack(spacing: 4) {
                                Text(background.title)
                                Spacer(minLength: 0)
                                if selectedBackground == background.rawValue {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.brand)
                                }
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        }
                        .padding(8)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(selectedBackground == background.rawValue ? Color.brand : .clear, lineWidth: 2)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedBackground == background.rawValue ? .isSelected : [])
                }
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(String(localized: "config-background"))
    }
}
