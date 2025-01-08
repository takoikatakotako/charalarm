import SwiftUI
import UIKit
import SDWebImageSwiftUI

struct CharaListView: View {
    @StateObject var viewState: CharacterListViewState
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    var body: some View {
        NavigationView {
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
            .edgesIgnoringSafeArea(.bottom)
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
            .navigationBarTitle(String(localized: "character-character-list"), displayMode: .inline)
            .navigationBarItems(
                leading:
                    CloseBarButton {
                        presentationMode.wrappedValue.dismiss()
                    }
            )
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
