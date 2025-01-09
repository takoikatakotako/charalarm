import SwiftUI

struct TutorialThirdView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            Image(.tutorialAlarmScreenShot)
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 400)
                .padding(.bottom, 36)

            Text(String(localized: "tutorial-did-you-get-a-call"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)

            Text(String(localized: "tutorial-you-can-set-multiple-alarms"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)

            Spacer()

            NavigationLink(
                destination: TutorialCharaListView(),
                label: {
                    TutorialButtonContent(text: String(localized: "common-next"))
                        .padding(.horizontal, 16)
                })
                .padding(.bottom, 28)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("")
        .navigationBarHidden(true)
    }
}

struct TutorialThirdView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TutorialThirdView()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))

            TutorialThirdView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        }
    }
}
