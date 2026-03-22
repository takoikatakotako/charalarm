import SwiftUI

struct UpdateRequiredView: View {
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "update-requird-update-requird"))
                .font(Font.system(size: 28))
                .padding()
            VStack(alignment: .leading) {
                Text(String(localized: "update-requird-update-requird"))
                Text(String(localized: "update-requird-please-install-the-latest-version"))
            }
            .padding()

            Image(R.image.zundamonNormal.name)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)

            Button(action: {
                if let url = URL(string: CharalarmAppStoreUrlString) {
                    openURL(url)
                }
            }) {
                Text(String(localized: "update-requird-open-app-store"))
                    .font(Font.system(size: 20))
            }
            .padding()
        }
    }
}

#Preview {
    UpdateRequiredView()
}
