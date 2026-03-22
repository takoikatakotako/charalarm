import SwiftUI

struct MaintenanceView: View {
    @Environment(\.openURL) private var openURL
    var body: some View {
        VStack(spacing: 12) {
            Text("メンテナンス中です")
                .font(Font.system(size: 28))
                .padding()
            VStack(alignment: .leading) {
                Text("メンテナンス終了までお待ちください。")
                Text("メンテナンスの状況はTwitterでお知らせしています。")
            }
            .padding()

            Button(action: {
                if let url = URL(string: OfficialTwitterUrlString) {
                    openURL(url)
                }
            }) {
                Text("キャラームのTwitterを開く")
                    .font(Font.system(size: 20))
            }
            .padding()
        }
    }
}

#Preview {
    MaintenanceView()
}
