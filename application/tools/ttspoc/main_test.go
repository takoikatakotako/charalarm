package main

import (
	"bytes"
	"testing"
)

func TestEncodeAndParseWAV(t *testing.T) {
	pcm := []byte{1, 2, 3, 4, 5, 6}
	f, err := parseWAVFormat(encodeWAV(pcm, 24000))
	if err != nil {
		t.Fatal(err)
	}
	if f.sampleRate != 24000 || f.channels != 1 || f.bitsPerSample != 16 || !bytes.Equal(f.data, pcm) {
		t.Fatalf("unexpected format: %+v", f)
	}
}

func TestToPCM(t *testing.T) {
	pcm := []byte{1, 2, 3, 4}

	got, rate := toPCM(encodeWAV(pcm, 16000), "audio/wav")
	if !bytes.Equal(got, pcm) || rate != 16000 {
		t.Fatalf("wav: got %v %d", got, rate)
	}

	got, rate = toPCM(pcm, "audio/L16;codec=pcm;rate=24000")
	if !bytes.Equal(got, pcm) || rate != 24000 {
		t.Fatalf("l16: got %v %d", got, rate)
	}
}
