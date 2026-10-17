package service

import (
	"errors"
	"fmt"
	"regexp"
	"sort"
	"time"

	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

var (
	// ErrInvalidChara は入力がキャラのタイプに合わないときのエラー。
	ErrInvalidChara = errors.New("invalid chara")
	// ErrCharaAlreadyExists は追加しようとした charaID のキャラがもうあるときのエラー。
	ErrCharaAlreadyExists = errors.New("chara already exists")
)

// charaIDPattern はリバースドメイン形式 (例: com.charalarm.yui)。S3 のパスにも使う。
var charaIDPattern = regexp.MustCompile(`^[a-z0-9-]+(\.[a-z0-9-]+)+$`)

type Chara struct {
	AWS infrastructure.AWS
}

// ScanCharas キャラ一覧を表示順 (displayOrder の昇順、同じなら charaID 順) で返す (enable の有無に関わらず全件)。
func (s *Chara) ScanCharas() ([]output.Chara, error) {
	charaList, err := s.AWS.GetCharaList()
	if err != nil {
		return nil, err
	}

	out := make([]output.Chara, 0, len(charaList))
	for _, c := range charaList {
		out = append(out, toCharaOutput(c))
	}
	sort.SliceStable(out, func(i, j int) bool {
		if out[i].Settings.DisplayOrder != out[j].Settings.DisplayOrder {
			return out[i].Settings.DisplayOrder < out[j].Settings.DisplayOrder
		}
		return out[i].CharaID < out[j].CharaID
	})
	return out, nil
}

// GetChara 指定 charaID のキャラを返す。
func (s *Chara) GetChara(charaID string) (output.Chara, error) {
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

// CreateChara キャラを追加する。calls と expressions は空で作り、リソースと一緒にあとから足す。
func (s *Chara) CreateChara(charaID string, settings output.CharaSettings) (output.Chara, error) {
	if !charaIDPattern.MatchString(charaID) {
		return output.Chara{}, fmt.Errorf("%w: charaID はリバースドメイン形式 (例: com.charalarm.yui) にしてください", ErrInvalidChara)
	}
	if err := validateCharaSettings(settings); err != nil {
		return output.Chara{}, err
	}

	today := time.Now().Format("2006-01-02")
	chara := database.Chara{
		CharaID:     charaID,
		CreatedAt:   today,
		UpdatedAd:   today,
		Profiles:    []database.CharaProfile{},
		Expressions: map[string]database.CharaExpression{},
		Calls:       []database.CharaCall{},
	}
	applyCharaSettings(&chara, settings)

	if err := s.AWS.CreateChara(chara); err != nil {
		var conditionalCheckFailed *types.ConditionalCheckFailedException
		if errors.As(err, &conditionalCheckFailed) {
			return output.Chara{}, ErrCharaAlreadyExists
		}
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

// UpdateChara 既存キャラの設定を更新する (calls と expressions はそのまま)。
func (s *Chara) UpdateChara(charaID string, settings output.CharaSettings) (output.Chara, error) {
	if err := validateCharaSettings(settings); err != nil {
		return output.Chara{}, err
	}

	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}

	applyCharaSettings(&chara, settings)
	chara.UpdatedAd = time.Now().Format("2006-01-02")

	if err := s.AWS.UpsertChara(chara); err != nil {
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

// validateCharaSettings はタイプごとに必要な項目がそろっているかを確かめる。
func validateCharaSettings(settings output.CharaSettings) error {
	if settings.Name == "" {
		return fmt.Errorf("%w: 名前を入れてください", ErrInvalidChara)
	}

	switch settings.AppearanceType {
	case database.AppearanceTypeIllustration:
	case database.AppearanceTypeVRM:
		// 準備中は VRM がなくてもよいが、有効にするなら要る
		if settings.Enable && settings.VRMFileName == "" {
			return fmt.Errorf("%w: VRM のキャラを有効にするには、VRM のファイル名を入れてください", ErrInvalidChara)
		}
	default:
		return fmt.Errorf("%w: 見た目のタイプ %q はありません", ErrInvalidChara, settings.AppearanceType)
	}

	switch settings.ConversationType {
	case database.ConversationTypeNone:
	case database.ConversationTypeVoicevox, database.ConversationTypeGemini:
		if settings.ConversationPrompt == "" {
			return fmt.Errorf("%w: 会話するキャラには人格プロンプトを入れてください", ErrInvalidChara)
		}
		if settings.ConversationType == database.ConversationTypeVoicevox && settings.VoicevoxStyleID < 0 {
			return fmt.Errorf("%w: VOICEVOX のスタイル ID は 0 以上にしてください", ErrInvalidChara)
		}
		if len(settings.ConversationLanguages) == 0 {
			return fmt.Errorf("%w: 会話できる言語を1つ以上選んでください", ErrInvalidChara)
		}
		for _, language := range settings.ConversationLanguages {
			if !database.IsSupportedLanguage(language) {
				return fmt.Errorf("%w: 会話の言語 %q はありません", ErrInvalidChara, language)
			}
			// VOICEVOX は日本語しか話せない
			if settings.ConversationType == database.ConversationTypeVoicevox && language != database.LanguageJapanese {
				return fmt.Errorf("%w: VOICEVOX のキャラは日本語でしか会話できません", ErrInvalidChara)
			}
		}
	default:
		return fmt.Errorf("%w: 会話のタイプ %q はありません", ErrInvalidChara, settings.ConversationType)
	}
	return nil
}

// applyCharaSettings は管理画面で編集する項目を chara に書く。
func applyCharaSettings(chara *database.Chara, settings output.CharaSettings) {
	chara.Enable = settings.Enable
	chara.Name = settings.Name
	chara.Description = settings.Description
	chara.Profiles = make([]database.CharaProfile, 0, len(settings.Profiles))
	for _, p := range settings.Profiles {
		chara.Profiles = append(chara.Profiles, database.CharaProfile{Title: p.Title, Name: p.Name, URL: p.URL})
	}
	chara.DisplayOrder = settings.DisplayOrder
	chara.AppearanceType = settings.AppearanceType
	chara.VRMFileName = settings.VRMFileName
	chara.ConversationType = settings.ConversationType
	// conversationType を書いたキャラは古い voiceProvider を使わない
	chara.VoiceProvider = ""
	chara.ConversationPrompt = settings.ConversationPrompt
	chara.VoicevoxStyleID = settings.VoicevoxStyleID
	chara.ConversationLanguages = settings.ConversationLanguages
	chara.GeminiVoice = settings.GeminiVoice
	chara.GeminiVoiceStyle = settings.GeminiVoiceStyle
	chara.CallOpeningPrompt = settings.CallOpeningPrompt
	chara.CallEndingPrompt = settings.CallEndingPrompt
	chara.CallNoInputEndingPrompt = settings.CallNoInputEndingPrompt
}

func toCharaOutput(c database.Chara) output.Chara {
	profiles := make([]output.CharaProfile, 0, len(c.Profiles))
	for _, p := range c.Profiles {
		profiles = append(profiles, output.CharaProfile{Title: p.Title, Name: p.Name, URL: p.URL})
	}

	calls := make([]output.CharaCall, 0, len(c.Calls))
	for _, call := range c.Calls {
		calls = append(calls, output.CharaCall{Message: call.Message, VoiceFileName: call.VoiceFileName})
	}

	expressions := make(map[string]output.CharaExpression, len(c.Expressions))
	for name, e := range c.Expressions {
		expressions[name] = output.CharaExpression{
			ImageFileNames: e.ImageFileNames,
			VoiceFileNames: e.VoiceFileNames,
		}
	}

	return output.Chara{
		CharaID:     c.CharaID,
		CreatedAt:   c.CreatedAt,
		UpdatedAt:   c.UpdatedAd,
		Calls:       calls,
		Expressions: expressions,
		Settings: output.CharaSettings{
			Enable:                  c.Enable,
			Name:                    c.Name,
			Description:             c.Description,
			Profiles:                profiles,
			DisplayOrder:            c.DisplayOrder,
			AppearanceType:          c.AppearanceTypeOf(),
			VRMFileName:             c.VRMFileName,
			ConversationType:        c.ConversationTypeOf(),
			ConversationPrompt:      c.ConversationPrompt,
			VoicevoxStyleID:         c.VoicevoxStyleID,
			ConversationLanguages:   c.ConversationLanguagesOf(),
			GeminiVoice:             c.GeminiVoice,
			GeminiVoiceStyle:        c.GeminiVoiceStyle,
			CallOpeningPrompt:       c.CallOpeningPrompt,
			CallEndingPrompt:        c.CallEndingPrompt,
			CallNoInputEndingPrompt: c.CallNoInputEndingPrompt,
		},
	}
}
