import SwiftUI

struct TutorialCharaListView: View {

    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            Image(R.image.tutorialCharaListScreenShot.name)
                .resizable()
                .scaledToFit()
                .frame(width: 320, height: 400)
                .padding(.bottom, 36)

            Spacer()

            Text(String(localized: "tutorial-you-can-see-the-characters"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)

            Text(String(localized: "tutorial-please-choose-your-favorite-character"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)

            Spacer()

            NavigationLink(
                destination: TutorialAcceptPrivacyPolicyView(),
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

struct TutorialFourthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TutorialCharaListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))

            TutorialCharaListView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        }
    }
}
