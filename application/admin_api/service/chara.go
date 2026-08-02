package service

import (
	"sort"

	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

type Chara struct {
	AWS infrastructure.AWS
}

// ScanCharas キャラ一覧を charaID 昇順で返す(enable の有無に関わらず全件)。
func (s *Chara) ScanCharas() ([]output.Chara, error) {
	charaList, err := s.AWS.GetCharaList()
	if err != nil {
		return nil, err
	}

	out := make([]output.Chara, 0, len(charaList))
	for _, c := range charaList {
		out = append(out, toCharaOutput(c))
	}
	sort.Slice(out, func(i, j int) bool {
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
		Enable:      c.Enable,
		CreatedAt:   c.CreatedAt,
		UpdatedAt:   c.UpdatedAd,
		Name:        c.Name,
		Description: c.Description,
		Profiles:    profiles,
		Calls:       calls,
		Expressions: expressions,
	}
}
