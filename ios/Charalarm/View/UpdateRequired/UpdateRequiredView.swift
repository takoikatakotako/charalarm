import SwiftUI

struct UpdateRequiredView: View {
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
                    UIApplication.shared.open(url)
                }
            }) {
                Text(String(localized: "update-requird-open-app-store"))
                    .font(Font.system(size: 20))
            }
            .padding()
        }
    }
}

struct UpdateRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            UpdateRequiredView()
                .previewDevice(PreviewDevice(rawValue: "iPhone X"))

            UpdateRequiredView()
                .previewDevice(PreviewDevice(rawValue: "iPhone 8"))
        }
    }
}
