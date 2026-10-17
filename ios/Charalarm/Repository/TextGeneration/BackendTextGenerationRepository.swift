import Foundation

/// backend `/chat` を叩いて会話応答を生成する本番実装。
/// LLM のプロバイダと認証はサーバ側が持ち、差し替えもサーバ側で完結する
/// （クライアントは会話履歴とその場の情報を送るだけ）。
struct BackendTextGenerationRepository: TextGenerationRepository {

    private let apiRepository = APIRepository()
    private let keychainRepository = KeychainRepository()
    private let userDefaultsRepository = UserDefaultsRepository()
    private let calendarRepository = CalendarRepository()

    /// キャラが端末の道具を使いたいと言ったら、道具を実行して結果を足して呼び直す（1ターンに1回まで）。
    /// 道具の結果（予定）は呼び出し側の会話の履歴には残さない（返すのは最後の返事だけ）。
    func generateResponse(
        charaID: String,
        language: ConversationLanguage,
        inputs: [ChatMessage],
        todayEvents todayEventsPolicy: TodayEventsPolicy,
        onFiller: @escaping @MainActor (String) -> Void
    ) async throws -> String {
        guard let userID = keychainRepository.getUserID(),
              let authToken = keychainRepository.getAuthToken() else {
            throw ConversationError.notAuthenticated
        }

        // 設定でオンにしていて、カレンダーの許可があるときだけ使える
        var capabilities: [String] = []
        if userDefaultsRepository.getUseCalendarInConversation() && calendarRepository.isAuthorized {
            capabilities.append("calendar.read")
        }

        // 電話の最初のひとことで、キャラのほうから今日の予定に触れてもらう（設定でオンにした人と、「今日の予定」ボタン）
        var todayEvents: String?
        let sendsTodayEvents: Bool
        switch todayEventsPolicy {
        case .none: sendsTodayEvents = false
        case .ifEnabled: sendsTodayEvents = userDefaultsRepository.getMentionScheduleOnCall()
        case .always: sendsTodayEvents = true
        }
        if sendsTodayEvents && calendarRepository.isAuthorized {
            todayEvents = calendarRepository.todayEventsJSON()
        }

        let response = try await apiRepository.postChat(
            userID: userID, authToken: authToken, charaID: charaID, language: language,
            capabilities: capabilities, todayEvents: todayEvents, messages: inputs, context: .current()
        )
        guard response.type == "toolCall", let calls = response.calls, !calls.isEmpty else {
            return response.message
        }

        // 道具を使うあいだのひとことを先に話してもらい、そのあいだに道具を実行する
        await onFiller(response.message)
        var messages = inputs
        messages.append(ChatMessage(role: .assistant, content: response.message, toolCalls: calls))
        for call in calls {
            messages.append(ChatMessage(role: .tool, content: runTool(name: call.name), toolCallID: call.id))
        }

        let finalResponse = try await apiRepository.postChat(
            userID: userID, authToken: authToken, charaID: charaID, language: language,
            capabilities: capabilities, messages: messages, context: .current()
        )
        return finalResponse.message
    }

    /// 端末の道具を実行する。知らない道具はエラーとして返す
    private func runTool(name: String) -> String {
        switch name {
        case "calendar.today":
            return calendarRepository.todayEventsJSON()
        default:
            return #"{"error":"unknown tool"}"#
        }
    }
}
