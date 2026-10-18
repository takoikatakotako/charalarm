import SwiftUI

struct UpdateRequiredView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(.zundamonNormal)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
            VStack(spacing: 8) {
                Text(String(localized: "update-requird-update-requird"))
                    .font(.title3.bold())
                Text(String(localized: "update-requird-please-install-the-latest-version"))
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            Spacer()
            if let url = URL(string: CharalarmAppStoreUrlString) {
                Link(destination: url) {
                    TutorialButtonContent(text: String(localized: "update-requird-open-app-store"))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    UpdateRequiredView()
}
