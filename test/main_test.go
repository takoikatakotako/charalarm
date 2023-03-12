package main

import (
	"bytes"
	"encoding/json"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/test/entity"
	"io/ioutil"
	"net/http"
	"testing"
)

const (
	Endpoint              = "https://api.sandbox.swiswiswift.com"
	HeaderApplicationJson = "application/json"
)

func TestScenario(t *testing.T) {
	// healthCheckにアクセスできる
	statusCode, healthCheckResponse, err := healthcheck()
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, statusCode, 200)
	assert.Equal(t, healthCheckResponse.Message, "Healthy!")

	// ユーザーの認証情報を生成
	userID := uuid.New().String()
	userToken := uuid.New().String()

	// 新規登録ができる
	statusCode, signUpResponse, err := userSignUp(userID, userToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, statusCode, 200)
	assert.Equal(t, "Sign Up Success!", signUpResponse.Message)

	// ユーザー情報を取得できる
	statusCode, userInfoResponse, err := userInfo(userID, userToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, statusCode, 200)
	assert.Equal(t, userInfoResponse.UserID, userID)
	assert.NotEqual(t, userInfoResponse.UserToken, userToken)

	// アラームの情報を生成
	alarmID := uuid.New().String()
	alarm := entity.AlarmRequest{
		AlarmID:      alarmID,
		UserID:       userID,
		AlarmType:    "VOIP_NOTIFICATION",
		AlarmEnable:  true,
		AlarmName:    "alarmName",
		AlarmHour:    12,
		AlarmMinute:  30,
		CharaID:      "",
		CharaName:    "charaName",
		VoiceFileURL: "voiceFileURL",
		Sunday:       true,
		Monday:       false,
		Tuesday:      true,
		Wednesday:    false,
		Thursday:     true,
		Friday:       false,
		Saturday:     true,
	}

	// アラームを追加
	statusCode, alarmAddResponse, err := alarmAdd(userID, userToken, alarm)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, statusCode, 200)
	assert.Equal(t, "アラーム追加完了!", alarmAddResponse.Message)

	// 退会できる
	statusCode, withdrawResponse, err := userWithdraw(userID, userToken)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}
	assert.Equal(t, statusCode, 200)
	assert.Equal(t, "Withdraw Success!", withdrawResponse.Message)
}

// Get: /healthcheck
func healthcheck() (int, entity.MessageResponse, error) {
	response, err := http.Get(Endpoint + "/healthcheck")
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	body, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	var healthCheckResponse entity.MessageResponse
	err = json.Unmarshal(body, &healthCheckResponse)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	return response.StatusCode, healthCheckResponse, nil
}

// Post: /user/signup
func userSignUp(userID string, userToken string) (int, entity.MessageResponse, error) {
	requestUrl := Endpoint + "/user/signup"

	requestBody := &entity.WithdrawRequest{
		UserID:    userID,
		UserToken: userToken,
	}

	jsonString, err := json.Marshal(requestBody)
	if err != nil {
		return 0, entity.MessageResponse{}, err
	}

	response, err := http.Post(requestUrl, HeaderApplicationJson, bytes.NewBuffer(jsonString))
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	responseBody, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	var signUpResponse entity.MessageResponse
	err = json.Unmarshal(responseBody, &signUpResponse)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	return response.StatusCode, signUpResponse, nil
}

// POST: /user/info
func userInfo(userID string, userToken string) (int, entity.UserInfoResponse, error) {
	requestUrl := Endpoint + "/user/info"

	request, err := http.NewRequest("POST", requestUrl, nil)
	if err != nil {
		return 0, entity.UserInfoResponse{}, err
	}
	request.Header.Add("Content-Type", "application/json")
	request.Header.Add("Authorization", createBasicAuthorizationHeader(userID, userToken))

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return 0, entity.UserInfoResponse{}, err
	}

	defer response.Body.Close()

	responseBody, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return response.StatusCode, entity.UserInfoResponse{}, err
	}

	var userInfoResponse entity.UserInfoResponse
	err = json.Unmarshal(responseBody, &userInfoResponse)
	if err != nil {
		return response.StatusCode, entity.UserInfoResponse{}, err
	}

	return response.StatusCode, userInfoResponse, nil
}

// POST: /user/withdraw
func userWithdraw(userID string, userToken string) (int, entity.MessageResponse, error) {
	requestUrl := Endpoint + "/user/withdraw"

	request, err := http.NewRequest("POST", requestUrl, nil)
	if err != nil {
		return 0, entity.MessageResponse{}, err
	}
	request.Header.Add("Content-Type", "application/json")
	request.Header.Add("Authorization", createBasicAuthorizationHeader(userID, userToken))

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return 0, entity.MessageResponse{}, err
	}

	defer response.Body.Close()

	responseBody, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	var signUpResponse entity.MessageResponse
	err = json.Unmarshal(responseBody, &signUpResponse)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	return response.StatusCode, signUpResponse, nil
}

// POST: /alarm/add
func alarmAdd(userID string, userToken string, alarm entity.AlarmRequest) (int, entity.MessageResponse, error) {
	requestUrl := Endpoint + "/alarm/add"

	requestBody := &entity.AlarmAddRequest{
		Alarm: alarm,
	}
	jsonString, err := json.Marshal(requestBody)
	if err != nil {
		return 0, entity.MessageResponse{}, err
	}

	request, err := http.NewRequest("POST", requestUrl, bytes.NewBuffer([]byte(jsonString)))
	if err != nil {
		return 0, entity.MessageResponse{}, err
	}
	request.Header.Add("Content-Type", "application/json")
	request.Header.Add("Authorization", createBasicAuthorizationHeader(userID, userToken))

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	responseBody, err := ioutil.ReadAll(response.Body)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	var userInfoResponse entity.MessageResponse
	err = json.Unmarshal(responseBody, &userInfoResponse)
	if err != nil {
		return response.StatusCode, entity.MessageResponse{}, err
	}

	return response.StatusCode, userInfoResponse, nil
}
