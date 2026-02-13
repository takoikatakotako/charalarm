import SwiftUI
import UIKit
import GoogleMobileAds

private struct AdmobBannerViewController: UIViewControllerRepresentable {
    let adUnitId: String

    init(adUnitID: String) {
        adUnitId = adUnitID
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let view = BannerView(adSize: AdSizeBanner)

        let viewController = UIViewController()
        view.adUnitID = adUnitId
        view.rootViewController = viewController
        viewController.view.addSubview(view)
        viewController.view.frame = CGRect(origin: .zero, size: AdSizeBanner.size)
        view.load(nil)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct AdmobBannerView: View {
    let adUnitID: String
    var body: some View {
        HStack {
            Spacer()
            AdmobBannerViewController(adUnitID: adUnitID)
                .frame(width: AdSizeBanner.size.width, height: AdSizeBanner.size.height, alignment: .center)
            Spacer()
        }
    }
}

struct BannerView_Previews: PreviewProvider {
    static var previews: some View {
        // TestUnitId
        AdmobBannerView(adUnitID: "ca-app-pub-3940256099942544/2934735716")
    }
}
