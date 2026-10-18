import SwiftUI
import SDWebImageSwiftUI

/// キャラの紹介の電話（アプリの中だけで鳴らす。CallKit は使わない）
struct CallView: View {
    @Environment(\.dismiss) private var dismiss

    @State var viewState: CallViewState

    var body: some View {
        ZStack {
            CallBackground()

            VStack(spacing: 0) {
                WebImage(url: URL(string: viewState.charaThumbnailUrlString)) { image in
                    image.resizable()
                } placeholder: {
                    Image(.characterPlaceholder)
                        .resizable()
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .opacity(viewState.overlay ? 0.25 : 1)

                CallerNameText(name: viewState.charaName)
                    .padding(.top, 32)

                Spacer()

                HStack {
                    CallActionButton(kind: .decline) {
                        viewState.fadeOut()
                        dismiss()
                    }
                    if viewState.overlay {
                        Spacer()
                        CallActionButton(kind: .answer) {
                            viewState.call()
                            withAnimation {
                                viewState.overlay = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 56)
                .padding(.bottom, 64)
            }
        }
        .onAppear {
            viewState.incoming()
        }
    }
}

#Preview {
    CallView(viewState: CallViewState(charaDomain: "com.charalarm.yui", charaName: "井上結衣"))
}
