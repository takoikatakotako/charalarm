// ttspoc は Gemini TTS（Vertex AI）の Voice Replication を検証するための CLI。
// 声の作成・一覧・削除と、文の合成・計測（遅延・音声長・概算コスト）を行う。
//
// 認証は `gcloud auth print-access-token` のトークンを使う。依存を増やさないため
// 標準ライブラリだけで書いている。詳細は README.md を参照。
package main

import (
	"bufio"
	"bytes"
	"encoding/base64"
	"encoding/binary"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const (
	defaultProject = "sandbox-492513"
	apiHost        = "https://aiplatform.googleapis.com"

	// 音声出力は 1 秒あたり 25 トークンとして課金される。
	audioTokensPerSecond = 25
)

// 出力 100 万トークンあたりの USD。Gemini API の発表時の価格で、Vertex AI の
// 価格表とは異なる可能性がある（2027-01-01 に倍額）。概算にだけ使う。
var outputPricePerMillion = map[string]float64{
	"gemini-3.8-flash-tts":      9,
	"gemini-3.8-flash-lite-tts": 6,
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	var err error
	switch os.Args[1] {
	case "create-voice":
		err = createVoice(os.Args[2:])
	case "list-voices":
		err = listVoices(os.Args[2:])
	case "delete-voice":
		err = deleteVoice(os.Args[2:])
	case "synth":
		err = synth(os.Args[2:])
	default:
		usage()
		os.Exit(2)
	}
	if err != nil {
		fmt.Fprintln(os.Stderr, "error:", err)
		os.Exit(1)
	}
}

func usage() {
	fmt.Fprintln(os.Stderr, `usage: ttspoc <command> [flags]

commands:
  create-voice  参照音声と同意音声から声を作成する
  list-voices   作成済みの声を一覧する
  delete-voice  声を削除する
  synth         文を合成して WAV を保存し、遅延などを計測する`)
}

// ---- voices ----

func createVoice(args []string) error {
	fs := flag.NewFlagSet("create-voice", flag.ExitOnError)
	project := fs.String("project", defaultProject, "GCP プロジェクト ID")
	source := fs.String("source", "", "参照音声（WAV, 24kHz, mono, 16bit, 10〜30秒）")
	consent := fs.String("consent", "", "同意文の読み上げ音声（WAV, 24kHz, mono, 16bit）")
	name := fs.String("name", "", "表示名")
	_ = fs.Parse(args)

	if *source == "" || *consent == "" {
		return errors.New("-source と -consent は必須")
	}
	sourceData, err := readVoiceWAV(*source)
	if err != nil {
		return err
	}
	consentData, err := readVoiceWAV(*consent)
	if err != nil {
		return err
	}

	body := map[string]any{
		"store": true,
		"voice": map[string]any{
			"type":        "VOICE_TYPE_REPLICATED",
			"displayName": *name,
			"replicated": map[string]any{
				"sourceAudio":  map[string]string{"mimeType": "audio/wav", "data": base64.StdEncoding.EncodeToString(sourceData)},
				"consentAudio": map[string]string{"mimeType": "audio/wav", "data": base64.StdEncoding.EncodeToString(consentData)},
			},
		},
	}
	url := fmt.Sprintf("%s/v1beta1/projects/%s/locations/global/voices", apiHost, *project)
	resp, err := call(http.MethodPost, url, body)
	if err != nil {
		return err
	}
	fmt.Println(string(resp))
	return nil
}

type voice struct {
	ID           string `json:"id"`
	Type         string `json:"type"`
	DisplayName  string `json:"display_name"`
	LanguageCode string `json:"language_code"`
	Gender       string `json:"gender"`
	Description  string `json:"description"`
}

// listVoices は作成した声を一覧する。一覧には 2,000 以上ある既製の声も含まれるため、
// 既定では除外する。-lang を付けると、その言語の既製の声も表示する。
func listVoices(args []string) error {
	fs := flag.NewFlagSet("list-voices", flag.ExitOnError)
	project := fs.String("project", defaultProject, "GCP プロジェクト ID")
	lang := fs.String("lang", "", "この言語の既製の声も表示する（例: ja-JP）")
	_ = fs.Parse(args)

	pageToken := ""
	for {
		url := fmt.Sprintf("%s/v1beta1/projects/%s/locations/global/voices?pageSize=1000", apiHost, *project)
		if pageToken != "" {
			url += "&pageToken=" + pageToken
		}
		resp, err := call(http.MethodGet, url, nil)
		if err != nil {
			return err
		}
		var page struct {
			Voices        []voice `json:"voices"`
			NextPageToken string  `json:"next_page_token"`
		}
		if err := json.Unmarshal(resp, &page); err != nil {
			return err
		}
		for _, v := range page.Voices {
			if v.Type == "VOICE_TYPE_PREBUILT" && (*lang == "" || v.LanguageCode != *lang) {
				continue
			}
			fmt.Printf("%s\t%s\t%s\t%s\t%s\n", v.ID, v.Type, v.DisplayName, v.Gender, v.Description)
		}
		if page.NextPageToken == "" {
			return nil
		}
		pageToken = page.NextPageToken
	}
}

func deleteVoice(args []string) error {
	fs := flag.NewFlagSet("delete-voice", flag.ExitOnError)
	project := fs.String("project", defaultProject, "GCP プロジェクト ID")
	voice := fs.String("voice", "", "削除する声の ID（voice_...）")
	_ = fs.Parse(args)

	if *voice == "" {
		return errors.New("-voice は必須")
	}
	url := fmt.Sprintf("%s/v1beta1/projects/%s/locations/global/voices/%s", apiHost, *project, *voice)
	resp, err := call(http.MethodDelete, url, nil)
	if err != nil {
		return err
	}
	fmt.Println(string(resp))
	return nil
}

// readVoiceWAV は Voice Replication が要求する形式（24kHz, mono, 16bit PCM）かを確かめて読む。
func readVoiceWAV(path string) ([]byte, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	format, err := parseWAVFormat(data)
	if err != nil {
		return nil, fmt.Errorf("%s: %w", path, err)
	}
	if format.sampleRate != 24000 || format.channels != 1 || format.bitsPerSample != 16 {
		return nil, fmt.Errorf("%s: %dHz/%dch/%dbit です。24000Hz/1ch/16bit に変換してください（README 参照）",
			path, format.sampleRate, format.channels, format.bitsPerSample)
	}
	return data, nil
}

// ---- synth ----

type result struct {
	model        string
	index        int
	text         string
	firstAudio   time.Duration
	total        time.Duration
	audioSeconds float64
	file         string
}

func synth(args []string) error {
	fs := flag.NewFlagSet("synth", flag.ExitOnError)
	project := fs.String("project", defaultProject, "GCP プロジェクト ID")
	voice := fs.String("voice", "", "声の ID（voice_...）")
	models := fs.String("models", "gemini-3.8-flash-tts,gemini-3.8-flash-lite-tts", "比較するモデル（カンマ区切り）")
	textFile := fs.String("text-file", "", "1 行 1 文のテキスト（省略時は組み込みの文）")
	style := fs.String("style", "", "話し方の指示（例: 明るく元気に、朝起こすように）")
	out := fs.String("out", "out", "WAV の出力先ディレクトリ")
	_ = fs.Parse(args)

	if *voice == "" {
		return errors.New("-voice は必須")
	}
	lines, err := loadLines(*textFile)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(*out, 0o755); err != nil {
		return err
	}

	var results []result
	for _, model := range strings.Split(*models, ",") {
		model = strings.TrimSpace(model)
		for i, text := range lines {
			r, err := synthesizeOne(*project, model, *voice, text, *style)
			if err != nil {
				return fmt.Errorf("%s #%d: %w", model, i+1, err)
			}
			r.index = i + 1
			r.file = filepath.Join(*out, fmt.Sprintf("%s-%02d.wav", model, i+1))
			if err := os.WriteFile(r.file, r.wav(), 0o644); err != nil {
				return err
			}
			results = append(results, r.result)
			fmt.Fprintf(os.Stderr, "done %s #%d\n", model, i+1)
		}
	}
	printReport(results)
	return nil
}

type synthesized struct {
	result
	pcm        []byte
	sampleRate int
}

func (s synthesized) wav() []byte {
	return encodeWAV(s.pcm, s.sampleRate)
}

// synthesizeOne はストリーミングで合成し、最初の音声が届くまでの時間と全体の時間を測る。
func synthesizeOne(project, model, voice, text, style string) (synthesized, error) {
	part := map[string]any{"text": text}
	if style != "" {
		part["speechMetadata"] = map[string]string{"style": style}
	}
	body := map[string]any{
		"contents": []any{map[string]any{"role": "user", "parts": []any{part}}},
		"generationConfig": map[string]any{
			"responseModalities": []string{"AUDIO"},
			"speechConfig": map[string]any{
				"voiceConfig": map[string]string{"voice": voice},
			},
		},
	}
	url := fmt.Sprintf("%s/v1/projects/%s/locations/global/publishers/google/models/%s:streamGenerateContent?alt=sse",
		apiHost, project, model)

	req, err := newRequest(http.MethodPost, url, body)
	if err != nil {
		return synthesized{}, err
	}
	start := time.Now()
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return synthesized{}, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		b, _ := io.ReadAll(resp.Body)
		return synthesized{}, fmt.Errorf("HTTP %d: %s", resp.StatusCode, b)
	}

	s := synthesized{result: result{model: model, text: text}, sampleRate: 24000}
	scanner := bufio.NewScanner(resp.Body)
	scanner.Buffer(make([]byte, 0, 1<<20), 64<<20)
	for scanner.Scan() {
		line := scanner.Text()
		if !strings.HasPrefix(line, "data: ") {
			continue
		}
		var chunk streamChunk
		if err := json.Unmarshal([]byte(strings.TrimPrefix(line, "data: ")), &chunk); err != nil {
			return synthesized{}, fmt.Errorf("SSE の解析に失敗: %w", err)
		}
		for _, c := range chunk.Candidates {
			for _, p := range c.Content.Parts {
				if p.InlineData == nil || p.InlineData.Data == "" {
					continue
				}
				audio, err := base64.StdEncoding.DecodeString(p.InlineData.Data)
				if err != nil {
					return synthesized{}, err
				}
				if s.firstAudio == 0 {
					s.firstAudio = time.Since(start)
				}
				pcm, rate := toPCM(audio, p.InlineData.MimeType)
				if rate > 0 {
					s.sampleRate = rate
				}
				s.pcm = append(s.pcm, pcm...)
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return synthesized{}, err
	}
	s.total = time.Since(start)
	if len(s.pcm) == 0 {
		return synthesized{}, errors.New("音声が返ってこなかった")
	}
	s.audioSeconds = float64(len(s.pcm)) / float64(s.sampleRate*2)
	return s, nil
}

type streamChunk struct {
	Candidates []struct {
		Content struct {
			Parts []struct {
				InlineData *struct {
					MimeType string `json:"mimeType"`
					Data     string `json:"data"`
				} `json:"inlineData"`
			} `json:"parts"`
		} `json:"content"`
	} `json:"candidates"`
}

// toPCM はチャンクが WAV ならヘッダを外し、audio/L16;rate=... ならそのまま PCM として扱う。
func toPCM(audio []byte, mimeType string) ([]byte, int) {
	if format, err := parseWAVFormat(audio); err == nil {
		return format.data, format.sampleRate
	}
	rate := 0
	for _, param := range strings.Split(mimeType, ";") {
		if v, ok := strings.CutPrefix(strings.TrimSpace(param), "rate="); ok {
			rate, _ = strconv.Atoi(v)
		}
	}
	return audio, rate
}

func printReport(results []result) {
	fmt.Println()
	fmt.Println("| model | # | 最初の音 | 合計 | 音声長 | 概算コスト | 文 |")
	fmt.Println("|---|---|---|---|---|---|---|")
	totals := map[string]float64{}
	for _, r := range results {
		cost := r.audioSeconds * audioTokensPerSecond * outputPricePerMillion[r.model] / 1_000_000
		totals[r.model] += r.audioSeconds
		fmt.Printf("| %s | %d | %.2fs | %.2fs | %.1fs | $%.5f | %s |\n",
			r.model, r.index, r.firstAudio.Seconds(), r.total.Seconds(), r.audioSeconds, cost, r.text)
	}
	fmt.Println()
	for model, seconds := range totals {
		perMinute := 60 * audioTokensPerSecond * outputPricePerMillion[model] / 1_000_000
		fmt.Printf("%s: 合計 %.1f 秒、音声 1 分あたり約 $%.4f（出力トークンのみ・Gemini API 価格での概算）\n",
			model, seconds, perMinute)
	}
}

func loadLines(path string) ([]string, error) {
	if path == "" {
		return defaultLines, nil
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var lines []string
	for _, l := range strings.Split(string(data), "\n") {
		if l = strings.TrimSpace(l); l != "" && !strings.HasPrefix(l, "#") {
			lines = append(lines, l)
		}
	}
	return lines, nil
}

// defaultLines は会話で実際に出そうな文。固有名詞・数字・時刻の読みも確かめる。
var defaultLines = []string{
	"おはよう！もう七時だよ、そろそろ起きよっか。",
	"今日は十時から定例ミーティング、十四時半から渋谷で打ち合わせがあるよ。",
	"大涌谷って読める？おおわくだに、だよ。",
	"昨日は遅くまでお疲れさま。でも、二度寝はだめだからね。",
	"わかった、じゃあ五分後にもう一回電話するね。いってらっしゃい！",
}

// ---- HTTP ----

func call(method, url string, body any) ([]byte, error) {
	req, err := newRequest(method, url, body)
	if err != nil {
		return nil, err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode/100 != 2 {
		return nil, fmt.Errorf("HTTP %d: %s", resp.StatusCode, b)
	}
	return b, nil
}

func newRequest(method, url string, body any) (*http.Request, error) {
	token, err := accessToken()
	if err != nil {
		return nil, err
	}
	var r io.Reader
	if body != nil {
		b, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		r = bytes.NewReader(b)
	}
	req, err := http.NewRequest(method, url, r)
	if err != nil {
		return nil, err
	}
	req.Header.Set("Authorization", "Bearer "+token)
	req.Header.Set("Content-Type", "application/json")
	return req, nil
}

var cachedToken string

func accessToken() (string, error) {
	if cachedToken != "" {
		return cachedToken, nil
	}
	out, err := exec.Command("gcloud", "auth", "print-access-token").Output()
	if err != nil {
		return "", fmt.Errorf("gcloud auth print-access-token に失敗: %w", err)
	}
	cachedToken = strings.TrimSpace(string(out))
	return cachedToken, nil
}

// ---- WAV ----

type wavFormat struct {
	channels      int
	sampleRate    int
	bitsPerSample int
	data          []byte
}

func parseWAVFormat(b []byte) (wavFormat, error) {
	if len(b) < 12 || string(b[0:4]) != "RIFF" || string(b[8:12]) != "WAVE" {
		return wavFormat{}, errors.New("WAV ではない")
	}
	var f wavFormat
	for pos := 12; pos+8 <= len(b); {
		id := string(b[pos : pos+4])
		size := int(binary.LittleEndian.Uint32(b[pos+4 : pos+8]))
		body := b[pos+8 : min(pos+8+size, len(b))]
		switch id {
		case "fmt ":
			if len(body) < 16 {
				return wavFormat{}, errors.New("fmt チャンクが短い")
			}
			f.channels = int(binary.LittleEndian.Uint16(body[2:4]))
			f.sampleRate = int(binary.LittleEndian.Uint32(body[4:8]))
			f.bitsPerSample = int(binary.LittleEndian.Uint16(body[14:16]))
		case "data":
			f.data = body
		}
		pos += 8 + size + size%2
	}
	if f.sampleRate == 0 || f.data == nil {
		return wavFormat{}, errors.New("fmt / data チャンクが見つからない")
	}
	return f, nil
}

func encodeWAV(pcm []byte, sampleRate int) []byte {
	var b bytes.Buffer
	b.WriteString("RIFF")
	_ = binary.Write(&b, binary.LittleEndian, uint32(36+len(pcm)))
	b.WriteString("WAVEfmt ")
	_ = binary.Write(&b, binary.LittleEndian, uint32(16))
	_ = binary.Write(&b, binary.LittleEndian, uint16(1)) // PCM
	_ = binary.Write(&b, binary.LittleEndian, uint16(1)) // mono
	_ = binary.Write(&b, binary.LittleEndian, uint32(sampleRate))
	_ = binary.Write(&b, binary.LittleEndian, uint32(sampleRate*2))
	_ = binary.Write(&b, binary.LittleEndian, uint16(2))
	_ = binary.Write(&b, binary.LittleEndian, uint16(16))
	b.WriteString("data")
	_ = binary.Write(&b, binary.LittleEndian, uint32(len(pcm)))
	b.Write(pcm)
	return b.Bytes()
}
