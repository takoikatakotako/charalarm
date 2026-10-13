package service

import (
	"fmt"
	"path"
	"regexp"
	"strings"
	"time"

	"github.com/takoikatakotako/charalarm/admin_api/service/output"
	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// uploadURLExpires は署名付き URL の有効期限。
const uploadURLExpires = 15 * time.Minute

// resourceFileNamePattern は S3 のキーにそのまま使えるファイル名。
var resourceFileNamePattern = regexp.MustCompile(`^[A-Za-z0-9][A-Za-z0-9._-]*$`)

// resourceContentTypes はアップロードできる拡張子と Content-Type。
var resourceContentTypes = map[string]string{
	".png":  "image/png",
	".jpg":  "image/jpeg",
	".jpeg": "image/jpeg",
	".caf":  "audio/x-caf",
	".mp3":  "audio/mpeg",
	".m4a":  "audio/mp4",
	".wav":  "audio/wav",
	".vrm":  "model/gltf-binary",
}

// CharaResource はキャラのリソース (画像・音声・VRM) のアップロードと、expressions / calls の編集。
type CharaResource struct {
	AWS            infrastructure.AWS
	Bucket         string
	DistributionID string
}

// BaseURL はリソースを配る URL。リソースのバケットは名前と同じドメインで CloudFront から配っている。
func (s *CharaResource) BaseURL() string {
	return "https://" + s.Bucket
}

// ListFiles は S3 の {charaID}/ にあるファイルを返す。
func (s *CharaResource) ListFiles(charaID string) ([]infrastructure.ResourceFile, error) {
	if _, err := s.AWS.GetChara(charaID); err != nil {
		return nil, err
	}
	return s.AWS.ListResourceFiles(s.Bucket, charaID)
}

// CreateUploadURL は {charaID}/{fileName} に PUT する署名付き URL と、PUT に付ける Content-Type を返す。
func (s *CharaResource) CreateUploadURL(charaID string, fileName string) (string, string, error) {
	contentType, err := resourceContentType(fileName)
	if err != nil {
		return "", "", err
	}
	if _, err := s.AWS.GetChara(charaID); err != nil {
		return "", "", err
	}

	url, err := s.AWS.PresignResourceUpload(s.Bucket, charaID, fileName, contentType, uploadURLExpires)
	if err != nil {
		return "", "", err
	}
	return url, contentType, nil
}

// InvalidateFiles は上書きしたファイルを CloudFront のキャッシュから消す。
func (s *CharaResource) InvalidateFiles(charaID string, fileNames []string) error {
	if len(fileNames) == 0 {
		return nil
	}
	for _, fileName := range fileNames {
		if !resourceFileNamePattern.MatchString(fileName) {
			return fmt.Errorf("%w: ファイル名 %q は使えません", ErrInvalidChara, fileName)
		}
	}
	return s.AWS.InvalidateResourceFiles(s.DistributionID, charaID, fileNames)
}

// UpdateAssets は expressions と calls を更新する。指すファイルが S3 にあることを確かめる。
func (s *CharaResource) UpdateAssets(charaID string, expressions map[string]output.CharaExpression, calls []output.CharaCall) (output.Chara, error) {
	chara, err := s.AWS.GetChara(charaID)
	if err != nil {
		return output.Chara{}, err
	}

	files, err := s.AWS.ListResourceFiles(s.Bucket, charaID)
	if err != nil {
		return output.Chara{}, err
	}
	if err := validateAssets(expressions, calls, files); err != nil {
		return output.Chara{}, err
	}

	chara.Expressions = make(map[string]database.CharaExpression, len(expressions))
	for name, e := range expressions {
		chara.Expressions[name] = database.CharaExpression{
			ImageFileNames: e.ImageFileNames,
			VoiceFileNames: e.VoiceFileNames,
		}
	}
	chara.Calls = make([]database.CharaCall, 0, len(calls))
	for _, call := range calls {
		chara.Calls = append(chara.Calls, database.CharaCall{Message: call.Message, VoiceFileName: call.VoiceFileName})
	}
	chara.UpdatedAd = time.Now().Format("2006-01-02")

	if err := s.AWS.UpsertChara(chara); err != nil {
		return output.Chara{}, err
	}
	return toCharaOutput(chara), nil
}

func resourceContentType(fileName string) (string, error) {
	if !resourceFileNamePattern.MatchString(fileName) {
		return "", fmt.Errorf("%w: ファイル名は英数字と . _ - だけにしてください (%q)", ErrInvalidChara, fileName)
	}
	contentType, ok := resourceContentTypes[strings.ToLower(path.Ext(fileName))]
	if !ok {
		return "", fmt.Errorf("%w: アップロードできるのは png / jpg / caf / mp3 / m4a / wav / vrm です (%q)", ErrInvalidChara, fileName)
	}
	return contentType, nil
}

// validateAssets は expressions と calls が指すファイルがすべて S3 にあるかを確かめる。
func validateAssets(expressions map[string]output.CharaExpression, calls []output.CharaCall, files []infrastructure.ResourceFile) error {
	exists := make(map[string]bool, len(files))
	for _, f := range files {
		exists[f.FileName] = true
	}
	check := func(fileName string) error {
		if !exists[fileName] {
			return fmt.Errorf("%w: ファイル %q がアップロードされていません", ErrInvalidChara, fileName)
		}
		return nil
	}

	for name, e := range expressions {
		if name == "" {
			return fmt.Errorf("%w: 表情の名前を入れてください", ErrInvalidChara)
		}
		for _, fileName := range append(append([]string{}, e.ImageFileNames...), e.VoiceFileNames...) {
			if err := check(fileName); err != nil {
				return err
			}
		}
	}
	for _, call := range calls {
		if call.VoiceFileName == "" {
			return fmt.Errorf("%w: アラームのボイスのファイルを選んでください", ErrInvalidChara)
		}
		if err := check(call.VoiceFileName); err != nil {
			return err
		}
	}
	return nil
}
