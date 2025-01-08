import SwiftUI
import AdSupport
import AppTrackingTransparency

struct TutorialRequireTrackingView: View {
    @State var goNextView = false
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            Text(String(localized: "tutorial-customize-your-ads"))
                .font(Font.system(size: 18).bold())

            Text(String(localized: "tutorial-charalarm-development-is-supported-by-advertising-revenue"))
                .font(Font.system(size: 18))
                .padding(.horizontal, 12)

            Image(R.image.zundamonNormal.name)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)

            NavigationLink(
                destination: TutorialFinallyView(),
                isActive: $goNextView,
                label: {
                    EmptyView()
                })

            Spacer()

            Button(action: {
                requestTrackingAuthorization()
            }, label: {
                TutorialButtonContent(text: String(localized: "common-next"))
                    .padding(.horizontal, 16)
            })
            .padding(.bottom, 28)
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    func requestTrackingAuthorization() {
        ATTrackingManager.requestTrackingAuthorization { _ in
            goNextView = true
        }
    }
}

struct TutorialRequireTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialRequireTrackingView()
    }
}
