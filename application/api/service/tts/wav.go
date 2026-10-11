package tts

import (
	"bytes"
	"encoding/binary"
	"errors"
	"strconv"
	"strings"
)

// toPCM は音声データを 16bit mono の PCM にそろえる。
// WAV ならヘッダを外し、audio/L16;rate=... ならそのまま PCM として扱う。
func toPCM(audio []byte, mimeType string) ([]byte, int) {
	if pcm, rate, err := parseWAV(audio); err == nil {
		return pcm, rate
	}
	rate := 0
	for _, param := range strings.Split(mimeType, ";") {
		if v, ok := strings.CutPrefix(strings.TrimSpace(param), "rate="); ok {
			rate, _ = strconv.Atoi(v)
		}
	}
	return audio, rate
}

// parseWAV は WAV から PCM とサンプリングレートを取り出す。
func parseWAV(b []byte) ([]byte, int, error) {
	if len(b) < 12 || string(b[0:4]) != "RIFF" || string(b[8:12]) != "WAVE" {
		return nil, 0, errors.New("not a wav")
	}
	rate := 0
	for i := 12; i+8 <= len(b); {
		id := string(b[i : i+4])
		size := int(binary.LittleEndian.Uint32(b[i+4 : i+8]))
		body := i + 8
		if body+size > len(b) {
			size = len(b) - body
		}
		switch id {
		case "fmt ":
			if size >= 8 {
				rate = int(binary.LittleEndian.Uint32(b[body+4 : body+8]))
			}
		case "data":
			return b[body : body+size], rate, nil
		}
		i = body + size + size%2
	}
	return nil, 0, errors.New("wav has no data chunk")
}

// encodeWAV は 16bit mono の PCM に WAV ヘッダを付ける。
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
