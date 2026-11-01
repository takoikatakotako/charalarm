import SwiftUI

private enum AppIconOption: String, CaseIterable, Identifiable {
    case yui
    case clockHug = "clock-hug"
    case shiori

    var id: String { rawValue }

    var title: String {
        switch self {
        case .clockHug: String(localized: "app-icon-clock-hug-name")
        case .yui: String(localized: "app-icon-yui-name")
        case .shiori: String(localized: "app-icon-shiori-name")
        }
    }

    var previewImage: ImageResource {
        switch self {
        case .clockHug: .appIconClockHugPreview
        case .yui: .appIconYuiPreview
        case .shiori: .appIconShioriPreview
        }
    }
}

struct AppIconSelectionView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedIcon: AppIconOption?
    @State private var pendingIcon: AppIconOption?
    @State private var showingError = false

    // このビルドに同梱された代替アイコン名を使い、環境をまたいだアイコンを選ばない。
    private func alternateIconName(for icon: AppIconOption) -> String? {
        let prefix: String
        switch icon {
        case .yui: return nil
        case .clockHug: prefix = "AppIcon-ClockHug-"
        case .shiori: prefix = "AppIcon-Shiori-"
        }
        let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any]
        let alternates = icons?["CFBundleAlternateIcons"] as? [String: Any]
        return alternates?.keys.first { $0.hasPrefix(prefix) }
    }

    private var canChangeIcon: Bool {
        UIApplication.shared.supportsAlternateIcons
            && AppIconOption.allCases.filter { $0 != .yui }.allSatisfy { alternateIconName(for: $0) != nil }
    }

    var body: some View {
        List {
            Section {
                ForEach(AppIconOption.allCases) { icon in
                    Button {
                        Task { await select(icon) }
                    } label: {
                        iconRow(icon)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canChangeIcon || pendingIcon != nil || selectedIcon == icon)
                    .accessibilityIdentifier("app-icon-\(icon.rawValue)")
                    .accessibilityLabel(icon.title)
                    .accessibilityValue(selectedIcon == icon ? String(localized: "app-icon-selected") : "")
                    .accessibilityAddTraits(selectedIcon == icon ? .isSelected : [])
                }
            } footer: {
                Text(String(localized: canChangeIcon ? "app-icon-footer" : "app-icon-unavailable"))
            }
        }
        .navigationTitle(String(localized: "config-app-icon"))
        .navigationBarTitleDisplayMode(.inline)
        .task { refreshSelection() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                refreshSelection()
            }
        }
        .alert(String(localized: "Error"), isPresented: $showingError) {
            Button(String(localized: "common-close"), role: .cancel) {}
        } message: {
            Text(String(localized: "app-icon-change-failed"))
        }
    }

    private func iconRow(_ icon: AppIconOption) -> some View {
        HStack(spacing: 16) {
            Image(icon.previewImage)
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(icon.title)
                    .font(.body.weight(.medium))
                if icon == .yui {
                    Text(String(localized: "app-icon-default"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .foregroundStyle(.primary)

            Spacer()

            if pendingIcon == icon {
                ProgressView()
                    .accessibilityLabel(String(localized: "app-icon-changing"))
            } else if selectedIcon == icon {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.brand)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }

    private func refreshSelection() {
        // UserDefaults に複製せず、再起動後も iOS が保持する実際の選択を表示する。
        if let name = UIApplication.shared.alternateIconName {
            selectedIcon = AppIconOption.allCases.first { alternateIconName(for: $0) == name }
        } else {
            selectedIcon = .yui
        }
    }

    private func select(_ icon: AppIconOption) async {
        guard canChangeIcon, pendingIcon == nil, selectedIcon != icon else { return }
        let alternateName: String?
        if icon != .yui {
            guard let name = alternateIconName(for: icon) else { return }
            alternateName = name
        } else {
            // nil を渡すとデフォルトの井上結衣に戻る。
            alternateName = nil
        }

        pendingIcon = icon
        defer {
            pendingIcon = nil
            refreshSelection()
        }

        do {
            try await UIApplication.shared.setAlternateIconName(alternateName)
        } catch {
            showingError = true
        }
    }
}
