import XCTest

/// アプリの主な画面を順にたどって、画面写真を残す（デザインの見直し用）。
/// 結果の .xcresult から写真を取り出して見比べる。
/// 撮る前に、その画面にしかない要素で画面に移れたことを確かめる（移れなければそこで失敗にする）。
final class ScreenTourTests: XCTestCase {
    private let app = XCUIApplication()

    override func setUp() {
        // 移れなかった画面を違う名前で撮らないよう、最初の失敗で止める
        continueAfterFailure = false
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

    func testAppIconSelection() {
        app.launchArguments.append("--ui-test-settings")
        app.launch()
        openAppIconSelection()
        selectAppIcon("logo")
        selectAppIcon("yui")
        snap("app-icon-yui")
        selectAppIcon("shiori")
        snap("app-icon-shiori")

        // iOS が持つ選択を再起動後にも表示できることを確かめる。
        app.terminate()
        app.launch()
        openAppIconSelection()
        XCTAssertEqual(app.buttons["app-icon-shiori"].value as? String, "選択中")

        // 結衣も代替アイコンとして選べることと、ロゴへの復帰を確かめる。
        selectAppIcon("yui")
        selectAppIcon("logo")
        snap("app-icon-logo")
    }

    private func openAppIconSelection() {
        require(app.navigationBars["設定"], "設定", timeout: 30)
        require(app.buttons["config-app-icon"], "設定のアプリアイコン").tap()
        require(app.navigationBars["アプリアイコン"], "アプリアイコン選択")
        require(app.buttons["app-icon-logo"], "Charalarmのロゴアイコン")
        require(app.buttons["app-icon-yui"], "結衣のアイコン")
        require(app.buttons["app-icon-shiori"], "しおりのアイコン")
    }

    private func selectAppIcon(_ name: String) {
        let button = app.buttons["app-icon-\(name)"].firstMatch
        if button.value as? String != "選択中" {
            XCTAssertTrue(button.isEnabled)
            button.tap()
            // UIKit が表示するアイコン変更の通知を閉じる。
            let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
            let confirmation = springboard.alerts.buttons["OK"].firstMatch
            if confirmation.waitForExistence(timeout: 5) {
                confirmation.tap()
            }
        }
        let selected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", "選択中"), object: button)
        XCTAssertEqual(XCTWaiter.wait(for: [selected], timeout: 10), .completed, "アイコンを \(name) に変更できませんでした")
    }

    func testScreenTour() {
        app.launch()

        // はじめてならチュートリアル、登録済みならホームが出る
        let tutorialStart = app.buttons["電話をしてもらう"].firstMatch
        let topCharaButton = app.buttons["キャラ"].firstMatch
        XCTAssertTrue(waitForAny([tutorialStart, topCharaButton], timeout: 30), "チュートリアルもホームも出ませんでした")

        if tutorialStart.exists {
            tourTutorial(start: tutorialStart)
        }

        // ホーム（キャラのダウンロードを待つ）
        require(app.buttons["キャラ"], "ホーム", timeout: 60)
        sleep(5)
        snap("10-top")

        // キャラをタップすると、下にセリフが出る
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.45)).tap()
        sleep(3)
        snap("10b-top-tap-line")

        // キャラ一覧 → キャラの紹介
        app.buttons["キャラ"].firstMatch.tap()
        require(app.navigationBars["キャラクター一覧"], "キャラ一覧")
        sleep(2)
        snap("11-chara-list")
        app.cells.firstMatch.tap()
        require(app.buttons["このキャラにする"], "キャラの紹介")
        sleep(3)
        snap("11b-chara-profile")
        app.navigationBars.buttons.firstMatch.tap()
        require(app.navigationBars["キャラクター一覧"], "キャラ一覧（戻った）")
        close()

        // アラーム一覧 → アラームの追加
        require(app.buttons["アラーム"], "ホーム").tap()
        require(app.navigationBars["アラーム"], "アラーム一覧")
        sleep(2)
        snap("12-alarm-list")
        require(app.buttons["アラーム追加"], "アラーム一覧の追加ボタン").tap()
        require(app.navigationBars["アラーム追加"], "アラームの追加")
        sleep(2)
        snap("12b-alarm-detail")
        close()
        require(app.navigationBars["アラーム"], "アラーム一覧（戻った）")
        close()

        // 設定 → プレミアムプラン
        require(app.buttons["設定"], "ホーム").tap()
        require(app.navigationBars["設定"], "設定")
        snap("13-config")
        require(app.buttons["背景"], "設定の背景").tap()
        require(app.navigationBars["背景"], "背景選択")
        require(app.buttons["和室"], "和室の背景")
        snap("13a-background")
        require(app.buttons["オフィス"], "オフィスの背景").tap()
        // SwiftUI の .isSelected は XCUIElement.isSelected に出ないので、選んだ見た目は写真で見る
        sleep(1)
        snap("13b-background-office")
        app.buttons["和室"].firstMatch.tap()
        app.navigationBars["背景"].buttons.firstMatch.tap()
        require(app.navigationBars["設定"], "設定（背景から戻った）")
        // 設定の項目が増えて、プレミアムプランは画面の外にある
        app.collectionViews.firstMatch.swipeUp()
        require(app.buttons["プレミアムプランについて"], "設定のプレミアムプラン").tap()
        require(app.navigationBars["プレミアムプラン"], "プレミアムプラン")
        sleep(2)
        snap("13b-subscription")
        close()
        require(app.navigationBars["設定"], "設定（戻った）")
        app.swipeUp()
        require(app.buttons["リセット"], "設定の下のほう")
        snap("14-config-bottom")
        close()

        // 話題のニュース・お知らせ（1つの画面のタブ）
        // はじめてなら、読んでいないお知らせがあるのでお知らせのタブから開く
        require(app.buttons["お知らせ"], "ホーム").tap()
        require(app.segmentedControls.buttons["話題"], "お知らせのタブ")
        sleep(2)
        snap("16-news")
        app.segmentedControls.buttons["話題"].firstMatch.tap()
        require(app.buttons["まとめて読んでもらう"], "話題のニュース")
        sleep(1)
        snap("15-trend-news")
        // スワイプでもお知らせに切り替わる
        app.buttons["まとめて読んでもらう"].firstMatch.swipeLeft()
        sleep(1)
        XCTAssertTrue(app.segmentedControls.buttons["お知らせ"].firstMatch.isSelected, "スワイプでお知らせに切り替わりませんでした")
        close()
        require(app.buttons["キャラ"], "ホーム（最後）")

        // 無料の人がニュースを読んでもらうときは、先にリワード広告を見るか聞く
        require(app.buttons["お知らせ"], "ホーム（2回目）").tap()
        require(app.segmentedControls.buttons["話題"], "お知らせ（2回目）").tap()
        require(app.buttons["まとめて読んでもらう"], "話題のニュース（2回目）").tap()
        require(app.alerts["広告を見て使いますか？"], "リワード広告の確認")
        snap("17-rewarded-prompt")
        app.alerts.buttons["キャンセル"].tap()
    }

    /// チュートリアルの7画面
    private func tourTutorial(start: XCUIElement) {
        snap("01-tutorial-intro")
        start.tap()

        require(app.buttons["answer"], "チュートリアルの着信")
        sleep(1)
        snap("02-tutorial-call")
        app.buttons["answer"].firstMatch.tap()

        // 電話に出て、ずんだもんが話し終わると「次へ」が出る
        require(app.buttons["次へ"], "チュートリアルの通話のあと", timeout: 15).tap()

        require(text(containing: "無事に電話がかかってきましたか"), "チュートリアル3")
        snap("03-tutorial-third")
        app.buttons["次へ"].firstMatch.tap()

        require(text(containing: "キャラクター一覧から着信を受けられる"), "チュートリアル4")
        snap("04-tutorial-chara-list")
        app.buttons["次へ"].firstMatch.tap()

        require(app.buttons["プライバシーポリシーに同意する"], "チュートリアル5")
        snap("05-tutorial-privacy")
        app.buttons["プライバシーポリシーに同意する"].firstMatch.tap()

        // ユーザー登録（development の API）が終わると次の画面に移る
        require(text(containing: "カスタマイズした広告を表示"), "チュートリアル6", timeout: 30)
        snap("06-tutorial-tracking")
        app.buttons["次へ"].firstMatch.tap()
        // トラッキングの許可のダイアログを閉じるきっかけ（割り込みの監視はアプリを触ったときに動く）
        sleep(2)
        app.tap()

        require(app.buttons["ホーム画面へ"], "チュートリアル7", timeout: 15)
        snap("07-tutorial-finally")
        app.buttons["ホーム画面へ"].firstMatch.tap()
    }

    /// その画面にしかない要素が出るのを待つ。出なければ失敗にして止める
    @discardableResult
    private func require(_ element: XCUIElement, _ screen: String, timeout: TimeInterval = 10) -> XCUIElement {
        let element = element.firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(screen) に移れませんでした")
        return element
    }

    private func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if elements.contains(where: \.exists) {
                return true
            }
            sleep(1)
        }
        return false
    }

    private func text(containing text: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// シートを閉じる（左上の閉じるボタン）
    private func close() {
        require(app.navigationBars.buttons["閉じる"], "閉じるボタン").tap()
        sleep(1)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
