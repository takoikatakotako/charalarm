import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct CharaListView: View {
    @StateObject var viewState: CharacterListViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                List(viewState.charaList) { chara in
                    NavigationLink(destination: CharaProfileView(viewState: CharaProfileViewState(chara: chara))) {
                        CharacterListRow(chara: chara)
                            .frame(height: 80)
                            .clipped()
                    }
                }

                VStack {
                    Spacer()
                    Button(action: {
                        viewState.characterAddRequestTapped()
                    }) {
                        CharacterListBanner()
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 28)
            }
            .ignoresSafeArea(.container, edges: .bottom)
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
                ToolbarItem(placement: .navigationBarLeading) {
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
