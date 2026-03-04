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
            .alert(isPresented: $viewState.showingAlert) {
                Alert(
                    title: Text(""),
                    message: Text(viewState.alertMessage),
                    dismissButton: .default(Text(String(localized: "common-close")))
                )
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

struct CharacterList_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CharaListView(viewState: CharacterListViewState())
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))

            CharaListView(viewState: CharacterListViewState())
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        }
    }
}
