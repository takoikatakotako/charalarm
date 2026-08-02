import Foundation

/// backend `/chat`（フェーズ4）実装前に会話ループを検証するための仮実装。
/// 実際の LLM は使わず、直近のメッセージからずんだもん風の返答を返す。
struct StubTextGenerationRepository: TextGenerationRepository {

    private let greetings = [
        "もしもし〜？ずんだもんなのだ！",
        "は〜い、ずんだもんなのだ！元気だったのだ？",
        "お電話ありがとうなのだ！どうしたのだ？"
    ]

    private let farewells = [
        "また電話してくれると嬉しいのだ〜！ばいばいなのだ！",
        "そろそろお別れなのだ。またねなのだ〜！"
    ]

    func generateResponse(charaID: String, inputs: [ChatMessage]) async throws -> String {
        // charaID はスタブでは未使用
        // 生成レイテンシを軽く模擬
        try? await Task.sleep(nanoseconds: 400_000_000)

        guard let last = inputs.last else {
            return greetings.randomElement()!
        }

        if last.role == ChatMessage.Role.system.rawValue {
            // 終了系プロンプトか初回プロンプトかで分岐
            if last.content.contains("終了") || last.content.contains("聞こえなくなった") {
                return farewells.randomElement()!
            }
            return greetings.randomElement()!
        }

        // ユーザー発話へのオウム返し（ずんだもん風）
        return "「\(last.content)」って言ったのだね！なるほどなのだ〜。もっと聞かせてほしいのだ！"
    }
}
