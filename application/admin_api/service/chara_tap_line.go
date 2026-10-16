package service

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/api/service/llm"
	"github.com/takoikatakotako/charalarm/api/service/tts"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// タップのセリフの上限
const (
	tapLineMaxLength        = 80
	tapLineMaxCount         = 300
	tapLineMaxDraftCount    = 20
	tapLineMaxVoicesPerCall = 8
)

// ErrVertexNotConfigured は Vertex AI (Gemini の LLM・TTS) を使えないときのエラー。
var ErrVertexNotConfigured = errors.New("vertex ai is not configured")

// TapLineTheme はセリフを作るときのテーマ。テーマに合わせて流す条件も決まる。
type TapLineTheme struct {
	Key   string
	Label string
	// Prompt は LLM に伝えるテーマの説明
	Prompt string
	When   database.CharaTapLineWhen
}

// TapLineThemes は選べるテーマ。季節のイベントは日付の条件つき。
var TapLineThemes = []TapLineTheme{
	{Key: "anytime", Label: "いつでも", Prompt: "いつ言ってもおかしくない、日常のひとこと"},
	{Key: "morning", Label: "朝", Prompt: "朝（5時〜11時）のひとこと。起きた人へのあいさつや、一日の始まり", When: database.CharaTapLineWhen{Hours: []int{5, 11}}},
	{Key: "daytime", Label: "昼", Prompt: "昼（11時〜17時）のひとこと。お昼ごはんや、午後のひと息", When: database.CharaTapLineWhen{Hours: []int{11, 17}}},
	{Key: "evening", Label: "夜", Prompt: "夜（17時〜23時）のひとこと。一日の終わりのねぎらい", When: database.CharaTapLineWhen{Hours: []int{17, 23}}},
	{Key: "midnight", Label: "深夜", Prompt: "深夜（23時〜5時）のひとこと。夜ふかしを気づかう", When: database.CharaTapLineWhen{Hours: []int{23, 5}}},
	{Key: "weekend", Label: "週末", Prompt: "土日のひとこと。休日ののんびりした時間", When: database.CharaTapLineWhen{Weekdays: []int{0, 6}}},
	{Key: "encourage", Label: "励まし", Prompt: "疲れている人や、がんばっている人への励まし"},
	{Key: "newyear", Label: "お正月", Prompt: "お正月（1月1日〜3日）のあいさつ", When: database.CharaTapLineWhen{Dates: []string{"01-01", "01-02", "01-03"}}},
	{Key: "valentine", Label: "バレンタイン", Prompt: "バレンタインデー（2月14日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"02-14"}}},
	{Key: "whiteday", Label: "ホワイトデー", Prompt: "ホワイトデー（3月14日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"03-14"}}},
	{Key: "tanabata", Label: "七夕", Prompt: "七夕（7月7日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"07-07"}}},
	{Key: "halloween", Label: "ハロウィン", Prompt: "ハロウィン（10月31日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"10-31"}}},
	{Key: "christmas", Label: "クリスマス", Prompt: "クリスマス（12月24日・25日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"12-24", "12-25"}}},
	{Key: "newyearseve", Label: "大みそか", Prompt: "大みそか（12月31日）のひとこと", When: database.CharaTapLineWhen{Dates: []string{"12-31"}}},
}

// tapLineDraftInstruction はセリフの下書きを作るときの決まり。
// ボイスは公開の S3 + CloudFront に置くので、個人情報やセンシティブな内容を入れさせない。
const tapLineDraftInstruction = `あなたはキャラクターのセリフを書く脚本家です。上のキャラクター設定に合わせて、アプリのホーム画面でユーザーがキャラをタップしたときに、キャラが話すひとことを書いてください。

決まり:
- 1つのセリフは1〜2文、40字くらいまで。そのまま音声で読み上げるので、話し言葉で書く
- 絵文字・顔文字・記号（✨★など）・かっこ書き・ト書きは使わない
- ユーザーの名前、実在の人名・会社名・地名、電話番号、メールアドレス、URL、数字の羅列は入れない
- ユーザーの予定・体調・個人的な事情を知っている前提で話さない
- 暴力的・性的・政治的・宗教的・差別的な内容や、不安をあおる内容は入れない
- 同じ言い回しを繰り返さず、それぞれ違うセリフにする

出力は、セリフの文字列だけを並べた JSON の配列にしてください（例: ["セリフ1", "セリフ2"]）。説明は書かないでください。`

// 公開する前に機械でも確かめる、個人情報に見えるもの
var tapLineSensitivePatterns = []*regexp.Regexp{
	regexp.MustCompile(`[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+`),                  // メールアドレス
	regexp.MustCompile(`(?i)https?://|www\.`),                               // URL
	regexp.MustCompile(`[0-9０-９]{2,4}[-ー－][0-9０-９]{2,4}[-ー－][0-9０-９]{3,4}`), // 電話番号
	regexp.MustCompile(`[0-9０-９]{5,}`),                                      // 長い数字の並び
}

var tapLineIDPattern = regexp.MustCompile(`^[a-z0-9]{8,32}$`)
var tapLineDatePattern = regexp.MustCompile(`^(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$`)

// CharaTapLine はタップのセリフの下書き・保存・ボイス作り。
type CharaTapLine struct {
	AWS            infrastructure.AWS
	Bucket         string
	DistributionID string
	// LLMClient と TTSClient は Vertex AI (Gemini)。設定がなければ nil で、下書きとボイスは作れない
	LLMClient llm.Client
	TTSClient tts.Client
	// DefaultVoice はキャラに Gemini の声の設定がないときの声
	DefaultVoice tts.Voice
}

// TapLineDraft は下書きのセリフ。保存はしない。
type TapLineDraft struct {
	Text  string
	Theme string
	When  database.CharaTapLineWhen
}

// Drafts はテーマに合わせたセリフの案を LLM に作らせる。
func (s *CharaTapLine) Drafts(ctx context.Context, charaID string, themeKey string, count int) ([]TapLineDraft, error) {
	if s.LLMClient == nil {
		return nil, ErrVertexNotConfigured
	}
	theme, ok := findTapLineTheme(themeKey)
	if !ok {
		return nil, fmt.Errorf("%w: テーマ %q はありません", ErrInvalidChara, themeKey)
	}
	if count < 1 || count > tapLineMaxDraftCount {
		return nil, fmt.Errorf("%w: 一度に作れるのは1〜%d個です", ErrInvalidChara, tapLineMaxDraftCount)
	}
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return nil, err
	}

	// 同じテーマのいまのセリフと重ならないようにする
	existing := make([]string, 0)
	for _, line := range chara.TapLines {
		if line.Theme == theme.Key {
			existing = append(existing, line.Text)
		}
	}
	request := fmt.Sprintf("テーマ: %s\n%d個書いてください。", theme.Prompt, count)
	if len(existing) > 0 {
		b, _ := json.Marshal(existing)
		request += "\n次のセリフはもうあるので、これとは違うものにしてください: " + string(b)
	}

	persona := chara.ConversationPrompt
	if persona == "" {
		persona = "キャラクターの名前: " + chara.Name + "\n" + chara.Description
	}
	reply, err := s.LLMClient.Chat(ctx, []llm.Message{
		{Role: llm.RoleSystem, Content: persona},
		{Role: llm.RoleSystem, Content: tapLineDraftInstruction},
		{Role: llm.RoleUser, Content: request},
	})
	if err != nil {
		return nil, err
	}

	texts, err := parseTapLineDrafts(reply)
	if err != nil {
		return nil, err
	}
	drafts := make([]TapLineDraft, 0, len(texts))
	for _, text := range texts {
		// 長すぎるものや、個人情報に見えるものは案から外す
		if text == "" || utf8.RuneCountInString(text) > tapLineMaxLength || checkTapLineSensitive(text) != nil {
			continue
		}
		drafts = append(drafts, TapLineDraft{Text: text, Theme: theme.Key, When: theme.When})
	}
	return drafts, nil
}

// SaveLines はセリフの一覧を保存する。文を変えたセリフは、ボイスを作り直すまでボイスなしにする。
func (s *CharaTapLine) SaveLines(charaID string, lines []database.CharaTapLine) (output.Chara, error) {
	if len(lines) > tapLineMaxCount {
		return output.Chara{}, fmt.Errorf("%w: セリフは%d個までです", ErrInvalidChara, tapLineMaxCount)
	}
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}

	current := make(map[string]database.CharaTapLine, len(chara.TapLines))
	for _, line := range chara.TapLines {
		current[line.ID] = line
	}
	saved := make([]database.CharaTapLine, 0, len(lines))
	seen := map[string]bool{}
	for _, line := range lines {
		if line.ID == "" {
			line.ID = newTapLineID()
		}
		line.Text = strings.TrimSpace(line.Text)
		if err := validateTapLine(line); err != nil {
			return output.Chara{}, err
		}
		if seen[line.ID] {
			return output.Chara{}, fmt.Errorf("%w: セリフの ID %q が重なっています", ErrInvalidChara, line.ID)
		}
		seen[line.ID] = true

		// ボイスはサーバが作ったものだけ。文が変わっていればボイスを外す
		line.VoiceFileName = ""
		if before, ok := current[line.ID]; ok && before.Text == line.Text {
			line.VoiceFileName = before.VoiceFileName
		}
		saved = append(saved, line)
	}

	chara.TapLines = saved
	chara.UpdatedAd = time.Now().Format("2006-01-02")
	if err := s.AWS.UpsertChara(chara); err != nil {
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

// MakeVoices は指定したセリフのボイスを Gemini TTS で作り、リソース (公開の S3 + CloudFront) に置く。
// 公開する前に、個人情報に見えるものがないかを確かめる。
func (s *CharaTapLine) MakeVoices(ctx context.Context, charaID string, lineIDs []string) (output.Chara, error) {
	if s.TTSClient == nil {
		return output.Chara{}, ErrVertexNotConfigured
	}
	if len(lineIDs) == 0 || len(lineIDs) > tapLineMaxVoicesPerCall {
		return output.Chara{}, fmt.Errorf("%w: 一度に作れるボイスは1〜%d個です", ErrInvalidChara, tapLineMaxVoicesPerCall)
	}
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}
	if chara.ConversationTypeOf() != database.ConversationTypeGemini {
		return output.Chara{}, fmt.Errorf("%w: ボイスを作れるのは、会話が Gemini のキャラだけです", ErrInvalidChara)
	}

	targets := map[string]bool{}
	for _, id := range lineIDs {
		targets[id] = true
	}
	voice := tapLineVoice(chara, s.DefaultVoice)
	made := make([]string, 0, len(lineIDs))
	for i, line := range chara.TapLines {
		if !targets[line.ID] {
			continue
		}
		if err := checkTapLineSensitive(line.Text); err != nil {
			return output.Chara{}, err
		}
		audio, err := s.TTSClient.Synthesize(ctx, line.Text, voice)
		if err != nil {
			return output.Chara{}, err
		}
		fileName := "tap-" + line.ID + ".wav"
		if err := s.AWS.PutResourceFile(s.Bucket, charaID, fileName, "audio/wav", audio.WAV); err != nil {
			return output.Chara{}, err
		}
		chara.TapLines[i].VoiceFileName = fileName
		made = append(made, fileName)
	}
	if len(made) == 0 {
		return output.Chara{}, fmt.Errorf("%w: 指定したセリフがありません", ErrInvalidChara)
	}

	chara.UpdatedAd = time.Now().Format("2006-01-02")
	if err := s.AWS.UpsertChara(chara); err != nil {
		return output.Chara{}, err
	}
	// 作り直したときのために、CloudFront のキャッシュを消す
	if err := s.AWS.InvalidateResourceFiles(s.DistributionID, charaID, made); err != nil {
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

func findTapLineTheme(key string) (TapLineTheme, bool) {
	for _, theme := range TapLineThemes {
		if theme.Key == key {
			return theme, true
		}
	}
	return TapLineTheme{}, false
}

// parseTapLineDrafts は LLM の返事 (JSON の配列。コードブロックで囲まれていることがある) を読む。
func parseTapLineDrafts(reply string) ([]string, error) {
	reply = strings.TrimSpace(reply)
	start := strings.Index(reply, "[")
	end := strings.LastIndex(reply, "]")
	if start < 0 || end <= start {
		return nil, errors.New("セリフの案を読めませんでした")
	}
	var texts []string
	if err := json.Unmarshal([]byte(reply[start:end+1]), &texts); err != nil {
		return nil, errors.New("セリフの案を読めませんでした")
	}
	for i := range texts {
		texts[i] = strings.TrimSpace(texts[i])
	}
	return texts, nil
}

// checkTapLineSensitive は、公開する前に個人情報に見えるものがないかを確かめる。
func checkTapLineSensitive(text string) error {
	for _, pattern := range tapLineSensitivePatterns {
		if pattern.MatchString(text) {
			return fmt.Errorf("%w: 個人情報に見える部分があるので公開できません: %q", ErrInvalidChara, text)
		}
	}
	return nil
}

func validateTapLine(line database.CharaTapLine) error {
	if !tapLineIDPattern.MatchString(line.ID) {
		return fmt.Errorf("%w: セリフの ID %q は使えません", ErrInvalidChara, line.ID)
	}
	if line.Text == "" || utf8.RuneCountInString(line.Text) > tapLineMaxLength {
		return fmt.Errorf("%w: セリフは1〜%d字にしてください", ErrInvalidChara, tapLineMaxLength)
	}
	if line.Theme != "" {
		if _, ok := findTapLineTheme(line.Theme); !ok {
			return fmt.Errorf("%w: テーマ %q はありません", ErrInvalidChara, line.Theme)
		}
	}
	for _, date := range line.When.Dates {
		if !tapLineDatePattern.MatchString(date) {
			return fmt.Errorf("%w: 日付 %q は MM-DD にしてください", ErrInvalidChara, date)
		}
	}
	if len(line.When.Hours) != 0 {
		if len(line.When.Hours) != 2 || line.When.Hours[0] < 0 || line.When.Hours[0] > 23 ||
			line.When.Hours[1] < 1 || line.When.Hours[1] > 24 || line.When.Hours[0] == line.When.Hours[1] {
			return fmt.Errorf("%w: 時間帯は [開始, 終了] (0〜24) にしてください", ErrInvalidChara)
		}
	}
	for _, weekday := range line.When.Weekdays {
		if weekday < 0 || weekday > 6 {
			return fmt.Errorf("%w: 曜日は 0 (日曜) 〜 6 (土曜) にしてください", ErrInvalidChara)
		}
	}
	return nil
}

func tapLineVoice(chara database.Chara, defaultVoice tts.Voice) tts.Voice {
	voice := defaultVoice
	if chara.GeminiVoice != "" {
		voice.Name = chara.GeminiVoice
	}
	if chara.GeminiVoiceStyle != "" {
		voice.Style = chara.GeminiVoiceStyle
	}
	return voice
}

func newTapLineID() string {
	b := make([]byte, 6)
	_, _ = rand.Read(b)
	return hex.EncodeToString(b)
}
