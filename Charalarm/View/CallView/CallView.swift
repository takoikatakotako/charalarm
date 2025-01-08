import SwiftUI
import UIKit
import SDWebImageSwiftUI

// TODO: モックであるようなことが伝わる名前にする
struct CallView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @StateObject var viewState: CallViewState

    var body: some View {
        ZStack {
            VStack {
                WebImage(url: URL(string: viewState.charaThumbnailUrlString))
                    .resizable()
                    .placeholder {
                        Image(R.image.characterPlaceholder.name)
                            .resizable()
                }
                    .animation(.easeInOut, value: 0.5)
                .transition(.fade)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                .scaledToFill()

                Text(viewState.charaName)
                    .font(Font.system(size: 40))
                    .foregroundColor(Color.black)
                    .padding(.top, 40)
                Spacer()

                Button(action: {
                    viewState.fadeOut()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "phone.fill.arrow.down.left")
                        .resizable()
                        .foregroundColor(Color.white)
                        .frame(width: 40, height: 40)
                }
                    .frame(width: 80, height: 80)
                .background(Color(R.color.callRed.name))
                    .cornerRadius(40)
            }                    .padding(.bottom, 60)

            if viewState.overlay {
                VStack {
                    Text(viewState.charaName)
                        .font(Font.system(size: 40))
                        .foregroundColor(Color.white)
                        .padding(.top, 100)
                    Spacer()

                    HStack(spacing: 160) {
                        Button(action: {
                            viewState.fadeOut()
                            presentationMode.wrappedValue.dismiss()
                        }) {

                            Image(systemName: "phone.fill.arrow.down.left")
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(width: 40, height: 40)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(R.color.callRed.name))
                        .cornerRadius(40)

                        Button(action: {
                            viewState.call()
                            withAnimation {
                                viewState.overlay = false
                            }
                        }) {
                            Image(systemName: "phone.fill")
                                .resizable()
                                .foregroundColor(Color.white)
                                .frame(width: 40, height: 40)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color(R.color.callGreen.name))
                        .cornerRadius(40)

                    }
                    .padding(.bottom, 60)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
        .onAppear {
            viewState.incoming()
        }
    }
}

struct CallView_Previews: PreviewProvider {
    static var previews: some View {
        CallView(viewState: CallViewState(charaDomain: "com.charalarm.yui", charaName: "井上結衣"))
    }
}
