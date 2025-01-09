import SwiftUI

struct MaintenanceView: View {
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
                    UIApplication.shared.open(url)
                }
            }) {
                Text("キャラームのTwitterを開く")
                    .font(Font.system(size: 20))
            }
            .padding()
        }
    }
}

struct MaintenanceView_Previews: PreviewProvider {
    static var previews: some View {
        MaintenanceView()
    }
}
