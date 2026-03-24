import SwiftUI
import UIKit
import SDWebImageSwiftUI

// TODO: モックであるようなことが伝わる名前にする
struct CallView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewState: CallViewState

    var body: some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack {
                    WebImage(url: URL(string: viewState.charaThumbnailUrlString)) { image in
                        image.resizable()
                    } placeholder: {
                        Image(R.image.characterPlaceholder.name)
                            .resizable()
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .scaledToFill()

                    Text(viewState.charaName)
                        .font(Font.system(size: 40))
                        .foregroundStyle(Color.white)
                        .padding(.top, 100)
                    Spacer()

                    Button(action: {
                        viewState.fadeOut()
                        dismiss()
                    }) {
                        Image(systemName: "phone.fill.arrow.down.left")
                            .resizable()
                            .foregroundStyle(Color.white)
                            .frame(width: 40, height: 40)
                    }
                    .frame(width: 80, height: 80)
                    .background(Color(R.color.callRed.name))
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                }                    .padding(.bottom, 60)

            }

            if viewState.overlay {
                    VStack {
                        Text(viewState.charaName)
                            .font(Font.system(size: 40))
                            .foregroundStyle(Color.white)
                            .padding(.top, 100)

                        Spacer()

                        HStack(spacing: 160) {
                            Button(action: {
                                viewState.fadeOut()
                                dismiss()
                            }) {

                                Image(systemName: "phone.fill.arrow.down.left")
                                    .resizable()
                                    .foregroundStyle(Color.white)
                                    .frame(width: 40, height: 40)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(R.color.callRed.name))
                            .clipShape(RoundedRectangle(cornerRadius: 40))

                            Button(action: {
                                viewState.call()
                                withAnimation {
                                    viewState.overlay = false
                                }
                            }) {
                                Image(systemName: "phone.fill")
                                    .resizable()
                                    .foregroundStyle(Color.white)
                                    .frame(width: 40, height: 40)
                            }
                            .frame(width: 80, height: 80)
                            .background(Color(R.color.callGreen.name))
                            .clipShape(RoundedRectangle(cornerRadius: 40))

                        }
                        .padding(.bottom, 60)
                    }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.gray)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .onAppear {
            viewState.incoming()
        }
    }
}

#Preview {
    CallView(viewState: CallViewState(charaDomain: "com.charalarm.yui", charaName: "井上結衣"))
}
