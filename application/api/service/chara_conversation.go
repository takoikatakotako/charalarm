package service

import (
	"github.com/takoikatakotako/charalarm/api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// 通話の場面のプロンプトの既定。キャラ情報 (chara-table) で上書きできる。
// アラームではキャラの方からユーザーに電話をかける。
const (
	defaultCallOpeningPrompt = "あなたからユーザーに電話をかけ、ユーザーが電話に出たところから会話を始めます。\n" +
		"ユーザーがアラームを設定した時刻に、約束どおり電話をかけています。謝る必要はありません。\n" +
		"最初のセリフは必ず「電話をかけた側として、出てくれたユーザーにかける挨拶」にしてください。\n" +
		"「お電話ありがとう」のような、電話を受けた側の言い方はしないでください。\n" +
		"毎回少し違う言い回しにしてください。"
	defaultCallEndingPrompt        = "会話時間が2分を超えたので、あなたらしい親しみやすい挨拶で電話を切ってください。"
	defaultCallNoInputEndingPrompt = "ユーザーの声が聞こえなくなったので、少し心配しつつ、あなたらしい親しみやすい挨拶で電話を切ってください。"
)

// isConversationChara は会話に対応するキャラか。アラーム専用のキャラと、人格プロンプトがないキャラは会話しない。
func isConversationChara(chara database.Chara) bool {
	return chara.ConversationTypeOf() != database.ConversationTypeNone && chara.ConversationPrompt != ""
}

// convertToCharaConversation は会話の設定を返す。会話に対応しないキャラは nil。
func convertToCharaConversation(chara database.Chara) *output.CharaConversation {
	if !isConversationChara(chara) {
		return nil
	}
	return &output.CharaConversation{
		VoiceProvider:       chara.ConversationTypeOf(),
		VoicevoxStyleID:     chara.VoicevoxStyleID,
		OpeningPrompt:       orDefault(chara.CallOpeningPrompt, defaultCallOpeningPrompt),
		EndingPrompt:        orDefault(chara.CallEndingPrompt, defaultCallEndingPrompt),
		NoInputEndingPrompt: orDefault(chara.CallNoInputEndingPrompt, defaultCallNoInputEndingPrompt),
	}
}

func orDefault(value string, defaultValue string) string {
	if value == "" {
		return defaultValue
	}
	return value
}
