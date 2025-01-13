package dynamodb

import (
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm-backend/entity/database"
	"testing"
	"time"
)

func TestDynamoDBRepository_InsertUser(t *testing.T) {
	// DynamoDBRepository
	repository := DynamoDBRepository{IsLocal: true}

	// ユーザー作成
	userID := uuid.New().String()
	authToken := uuid.New().String()
	insertUser := createUser(userID, authToken)
	err := repository.InsertUser(insertUser)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get
	getUser, err := repository.GetUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, userID, getUser.UserID)
	assert.Equal(t, authToken, getUser.AuthToken)
}

func TestInsertUserAndExist(t *testing.T) {
	// DynamoDBRepository
	repository := DynamoDBRepository{IsLocal: true}

	// UserInfo
	userID := uuid.New().String()
	authToken := uuid.New().String()

	// IsExist
	firstIsExist, err := repository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, firstIsExist, false)

	// Insert
	insertUser := createUser(userID, authToken)
	err = repository.InsertUser(insertUser)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// IsExist
	secondIsExist, err := repository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, secondIsExist, true)
}

func TestInsertUserAndDelete(t *testing.T) {
	// DynamoDBRepository
	repository := DynamoDBRepository{IsLocal: true}

	userID := uuid.New().String()
	authToken := uuid.New().String()

	// Insert
	insertUser := createUser(userID, authToken)
	err := repository.InsertUser(insertUser)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// IsExist
	firstIsExist, err := repository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, firstIsExist, true)

	// Delete
	err = repository.DeleteUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// IsExist
	secondIsExist, err := repository.IsExistUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, secondIsExist, false)
}

func TestDynamoDBRepository_UpdateUserPremiumPlan(t *testing.T) {
	// DynamoDBRepository
	repository := DynamoDBRepository{IsLocal: true}

	userID := uuid.New().String()
	authToken := uuid.New().String()

	// Insert
	insertUser := createUser(userID, authToken)
	err := repository.InsertUser(insertUser)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get User
	user, err := repository.GetUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, user.PremiumPlan, false)

	// Update
	err = repository.UpdateUserPremiumPlan(userID, true)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Get Updated User
	updatedUser, err := repository.GetUser(userID)
	if err != nil {
		t.Errorf("unexpected error: %v", err)
	}

	// Assert
	assert.Equal(t, updatedUser.PremiumPlan, true)
}

// private methods

func createUser(userID string, authToken string) database.User {
	platform := "iOS"
	currentTime := time.Now()
	ipAddress := "127.0.0.1"

	user := database.User{
		UserID:              userID,
		AuthToken:           authToken,
		Platform:            platform,
		PremiumPlan:         false,
		CreatedAt:           currentTime.Format(time.RFC3339),
		UpdatedAt:           currentTime.Format(time.RFC3339),
		RegisteredIPAddress: ipAddress,
	}

	return user
}
