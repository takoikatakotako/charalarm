import XCTest

/// アプリの主な画面を順にたどって、画面写真を残す（デザインの見直し用）。
/// 結果の .xcresult から写真を取り出して見比べる。
final class ScreenTourTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = true
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        // トラッキングや通知の許可のダイアログは許可する
        addUIInterruptionMonitor(withDescription: "System Dialog") { alert in
            for label in ["許可", "Allow", "OK", "アプリにトラッキングしないように要求", "Ask App Not to Track"] where alert.buttons[label].exists {
                alert.buttons[label].tap()
                return true
            }
            return false
        }
    }

    func testScreenTour() {
        app.launch()
        snap("01-tutorial-intro")

        if tapIfExists(app.buttons["電話をしてもらう"], timeout: 5) {
            sleep(3)
            snap("02-tutorial-call")
            // 着信に出る（右下の緑のボタン）
            if !tapIfExists(app.buttons["answer"], timeout: 2) {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.74, dy: 0.92)).tap()
            }
            sleep(3)
            snap("02b-tutorial-call-answered")
            // 着信の画面が終わり「つぎ」が出るのを待つ
            _ = tapIfExists(app.buttons.matching(NSPredicate(format: "label IN %@", ["つぎ", "次へ"])).firstMatch, timeout: 15)
            sleep(1)
            snap("03-tutorial-third")
            _ = tapIfExists(app.buttons["次へ"], timeout: 5)
            sleep(1)
            snap("04-tutorial-chara-list")
            _ = tapIfExists(app.buttons["次へ"], timeout: 5)
            sleep(1)
            snap("05-tutorial-privacy")
            _ = tapIfExists(app.buttons["プライバシーポリシーに同意する"], timeout: 5)
            sleep(3)
            snap("06-tutorial-tracking")
            _ = tapIfExists(app.buttons["次へ"], timeout: 5)
            sleep(2)
            app.tap() // 許可のダイアログを閉じるきっかけ
            sleep(1)
            snap("07-tutorial-finally")
            _ = tapIfExists(app.buttons["ホーム画面へ"], timeout: 10)
        }

        // ホーム（キャラのダウンロードを待つ）
        sleep(15)
        app.tap()
        sleep(2)
        snap("10-top")

        // 下のボタン: キャラ一覧・アラーム・電話・設定
        tapBottomButton("キャラ", at: 0.17)
        sleep(4)
        snap("11-chara-list")
        if tapIfExists(app.cells.firstMatch, timeout: 3) {
            sleep(4)
            snap("11b-chara-profile")
            app.navigationBars.buttons.firstMatch.tap()
            sleep(1)
        }
        dismissSheet()

        tapBottomButton("アラーム", at: 0.39)
        sleep(4)
        snap("12-alarm-list")
        if tapIfExists(app.buttons["アラーム追加"], timeout: 3) {
            sleep(3)
            snap("12b-alarm-detail")
            dismissSheet()
        }
        dismissSheet()

        tapBottomButton("設定", at: 0.83)
        sleep(3)
        snap("13-config")
        if tapIfExists(app.buttons["プレミアムプランについて"], timeout: 3) {
            sleep(3)
            snap("13b-subscription")
            _ = tapIfExists(app.buttons["閉じる"], timeout: 3)
            sleep(2)
        }
        app.swipeUp()
        sleep(1)
        snap("14-config-bottom")
        dismissSheet()

        // 上のボタン: 話題・お知らせ
        if tapIfExists(app.buttons["話題"], timeout: 2) {
            sleep(2)
            snap("15-trend-news")
            dismissSheet()
        }
        if !tapIfExists(app.buttons["お知らせ"], timeout: 2) {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.1)).tap()
        }
        sleep(3)
        snap("16-news")
        dismissSheet()
    }

    /// トップの下のボタン。名前で探し、なければ（古い見た目）位置で押す
    private func tapBottomButton(_ label: String, at x: CGFloat) {
        if !tapIfExists(app.buttons[label], timeout: 2) {
            app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: 0.9)).tap()
        }
    }

    private func dismissSheet() {
        app.swipeDown(velocity: .fast)
        sleep(2)
    }

    @discardableResult
    private func tapIfExists(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let element = element.firstMatch
        guard element.waitForExistence(timeout: timeout) else { return false }
        element.tap()
        return true
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
