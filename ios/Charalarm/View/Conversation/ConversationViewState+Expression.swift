import Foundation

// MARK: - Expression

/// 3D のキャラの表情。キャラの返事の頭に付けてもらった印（[happy] など）で変える
extension ConversationViewState {

    /// キャラの返事から表情の印を外し、印があれば 3D のキャラの表情を変える。字幕と読み上げには外したあとの文を使う
    func applyExpression(_ response: String) -> String {
        let parsed = VRMExpression.parse(response)
        if let expression = parsed.expression {
            self.expression = expression
        }
        return parsed.text
    }
}
