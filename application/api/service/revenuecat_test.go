package service

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
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
