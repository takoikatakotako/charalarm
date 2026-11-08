import SwiftUI

struct CharaListView: View {
    @State var viewState: CharacterListViewState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var myChara: MyChara?
    @State private var isMyCharaActive = false

    var body: some View {
        NavigationStack {
            List {
                // 自分のキャラ（プリセットか手持ちの VRM の見た目に、好きな名前を付ける）
                Section {
                    NavigationLink {
                        MyCharaView(viewState: MyCharaViewState())
                    } label: {
                        myCharaRow
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
                myChara = MyCharaRepository().load()
                isMyCharaActive = MyCharaRepository().isSelected
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
