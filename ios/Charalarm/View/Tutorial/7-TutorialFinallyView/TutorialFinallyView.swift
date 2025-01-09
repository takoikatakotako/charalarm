import SwiftUI

struct TutorialFinallyView: View {

    var body: some View {
        VStack(alignment: .center, spacing: 12) {

            Spacer()

            Text(String(localized: "tutorial-finally-please-allow-push-notificaion"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)
                .padding(.top, 128)

            Image(.zundamonSmile)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            Spacer()

            Button(action: {
                NotificationCenter.default.post(name: NSNotification.doneTutorial, object: self, userInfo: nil)
            }) {
                TutorialButtonContent(text: String(localized: "tutorial-go-to-home-screen"))
                    .padding(.horizontal, 16)
            }
            .padding(.bottom, 28)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct TutorialSixthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TutorialFinallyView()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))

            TutorialFinallyView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        }
    }
}
