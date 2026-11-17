import SwiftUI

struct CharaListView: View {
    // ブラッシュアップ中は作成・編集の入口だけを隠す。再開するときは true に戻す。
    // 作成済みのキャラや、そのキャラを使うアラーム・会話には影響させない。
    private static let showsMyCharaEditor = false

    @State var viewState: CharacterListViewState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var myChara: MyChara?
    @State private var isMyCharaActive = false

    var body: some View {
        NavigationStack {
            List {
                if Self.showsMyCharaEditor {
                    Section {
                        NavigationLink {
                            MyCharaView(viewState: MyCharaViewState())
                        } label: {
                            myCharaRow
                        }
                    }
                }

                Section {
                    ForEach(viewState.charaList) { chara in
                        NavigationLink {
                            CharaProfileView(viewState: CharaProfileViewState(chara: chara))
                        } label: {
                            CharacterListRow(chara: chara)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    openURL(viewState.openURLRepository.characterAdditionRequestURL)
                } label: {
                    CharacterListBanner()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .onAppear {
                viewState.fetchCharacters()
                if Self.showsMyCharaEditor {
                    myChara = MyCharaRepository().load()
                    isMyCharaActive = MyCharaRepository().isSelected
                }
            }
            .alert("", isPresented: $viewState.showingAlert) {
                Button(String(localized: "common-close")) {}
            } message: {
                Text(viewState.alertMessage)
            }
            .navigationTitle(String(localized: "character-character-list"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    CloseBarButton {
                        dismiss()
                    }
                }
            }
        }
    }
}

extension CharaListView {
    private var myCharaRow: some View {
        HStack(spacing: 12) {
            Image(systemName: myChara == nil ? "person.crop.circle.badge.plus" : "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(myChara?.name ?? String(localized: "my-chara-create"))
                Text(String(localized: "my-chara-title"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isMyCharaActive {
                Text(String(localized: "app-icon-selected"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CharaListView(viewState: CharacterListViewState())
}
