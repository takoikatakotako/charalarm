import SwiftUI

struct CharaListView: View {
    @State var viewState: CharacterListViewState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List(viewState.charaList) { chara in
                NavigationLink {
                    CharaProfileView(viewState: CharaProfileViewState(chara: chara))
                } label: {
                    CharacterListRow(chara: chara)
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

#Preview {
    CharaListView(viewState: CharacterListViewState())
}
