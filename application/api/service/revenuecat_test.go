package service

import (
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/takoikatakotako/charalarm/infrastructure"
)

func TestPremiumPlanChanges(t *testing.T) {
	now := time.Date(2026, 10, 22, 0, 0, 0, 0, time.UTC)
	future := now.Add(24 * time.Hour).UnixMilli()
	past := now.Add(-time.Hour).UnixMilli()

	tests := []struct {
		name  string
		event RevenueCatEvent
		want  map[string]bool
	}{
		{
			name:  "購入すると有効",
			event: RevenueCatEvent{Type: "INITIAL_PURCHASE", AppUserID: "u1", EntitlementIDs: []string{"premium"}, ExpirationAtMs: &future},
			want:  map[string]bool{"u1": true},
		},
		{
			name:  "解約しても期限までは有効",
			event: RevenueCatEvent{Type: "CANCELLATION", AppUserID: "u1", EntitlementIDs: []string{"premium"}, ExpirationAtMs: &future},
			want:  map[string]bool{"u1": true},
		},
		{
			name:  "返金されると期限が過去になり無効",
			event: RevenueCatEvent{Type: "CANCELLATION", AppUserID: "u1", EntitlementIDs: []string{"premium"}, ExpirationAtMs: &past},
			want:  map[string]bool{"u1": false},
		},
		{
			name:  "期限切れで無効",
			event: RevenueCatEvent{Type: "EXPIRATION", AppUserID: "u1", EntitlementIDs: []string{"premium"}, ExpirationAtMs: &past},
			want:  map[string]bool{"u1": false},
		},
		{
			name:  "ほかの Entitlement は無視",
			event: RevenueCatEvent{Type: "RENEWAL", AppUserID: "u1", EntitlementIDs: []string{"other"}, ExpirationAtMs: &future},
			want:  nil,
		},
		{
			name:  "移った先を有効、元を無効",
			event: RevenueCatEvent{Type: "TRANSFER", TransferredFrom: []string{"u1"}, TransferredTo: []string{"u2"}},
			want:  map[string]bool{"u1": false, "u2": true},
		},
		{
			name:  "テストイベントは何もしない",
			event: RevenueCatEvent{Type: "TEST", AppUserID: "u1"},
			want:  nil,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, premiumPlanChanges(tt.event, "premium", now))
		})
	}
}

func TestRevenueCatHandleEventIgnoresOldEvents(t *testing.T) {
	awsRepository := infrastructure.AWS{Profile: "local"}
	userService := User{AWS: awsRepository}
	revenueCat := RevenueCat{AWS: awsRepository, EntitlementID: "premium"}

	userID := uuid.New().String()
	authToken := uuid.New().String()
	assert.NoError(t, userService.Signup(userID, authToken, "iOS"))

	now := time.Now()
	future := now.Add(24 * time.Hour).UnixMilli()
	past := now.Add(-time.Hour).UnixMilli()
	premiumPlan := func() bool {
		user, err := userService.GetUser(userID, authToken)
		assert.NoError(t, err)
		return user.PremiumPlan
	}

	// 更新されて有効
	renewal := RevenueCatEvent{Type: "RENEWAL", AppUserID: userID, EntitlementIDs: []string{"premium"}, ExpirationAtMs: &future, EventTimestampMs: 2000}
	assert.NoError(t, revenueCat.HandleEvent(renewal, now))
	assert.True(t, premiumPlan())

	// それより前の期限切れが遅れて届いても無効にしない
	oldExpiration := RevenueCatEvent{Type: "EXPIRATION", AppUserID: userID, EntitlementIDs: []string{"premium"}, ExpirationAtMs: &past, EventTimestampMs: 1000}
	assert.NoError(t, revenueCat.HandleEvent(oldExpiration, now))
	assert.True(t, premiumPlan())

	// 新しい期限切れなら無効にする
	newExpiration := RevenueCatEvent{Type: "EXPIRATION", AppUserID: userID, EntitlementIDs: []string{"premium"}, ExpirationAtMs: &past, EventTimestampMs: 3000}
	assert.NoError(t, revenueCat.HandleEvent(newExpiration, now))
	assert.False(t, premiumPlan())

	// 同じイベントが重複して届いても変わらない
	assert.NoError(t, revenueCat.HandleEvent(renewal, now))
	assert.False(t, premiumPlan())
}
