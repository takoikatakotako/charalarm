import SwiftUI

struct TutorialIntroductionView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Spacer()

            Text(String(localized: "tutorial-welcome-to-charalarm"))
                .font(Font.system(size: 20))

            Text(String(localized: "tutorial-this-is-an-app"))
                .font(Font.system(size: 20))
                .padding(.horizontal, 12)

            Text(String(localized: "tutorial-let-us-try-it-now"))
                .font(Font.system(size: 20))

            Image(.zundamonNormal)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            Spacer()

            NavigationLink(
                destination: TutorialCallView(),
                label: {
                    TutorialButtonContent(text: String(localized: "tutorial-get-a-call"))
                        .padding(.horizontal, 16)
                })
                .padding(.bottom, 28)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .navigationTitle("")
        .toolbar(.hidden, for: .navigationBar)
        .background(Color.white.ignoresSafeArea())
    }
}

#Preview {
    TutorialIntroductionView()
}
