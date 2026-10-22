package service

import (
	"log/slog"
	"slices"
	"time"

	"github.com/takoikatakotako/charalarm/infrastructure"
	"github.com/takoikatakotako/charalarm/infrastructure/database"
)

// RevenueCat は RevenueCat の Webhook を受けて、ユーザーのプレミアムプランを更新する。
// 端末からの自己申告ではなく、RevenueCat (App Store) の購入状態をサーバの正とするため。
type RevenueCat struct {
	AWS           infrastructure.AWS
	EntitlementID string
}

// RevenueCatEvent は RevenueCat の Webhook のイベント (使う項目だけ)。
// https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields
type RevenueCatEvent struct {
	Type            string   `json:"type"`
	AppUserID       string   `json:"app_user_id"`
	EntitlementIDs  []string `json:"entitlement_ids"`
	ExpirationAtMs  *int64   `json:"expiration_at_ms"`
	TransferredFrom []string `json:"transferred_from"`
	TransferredTo   []string `json:"transferred_to"`
	Environment     string   `json:"environment"`
}

// HandleEvent はイベントに合わせてプレミアムプランを更新する。
// 知らないユーザーや関係ないイベントは無視する (エラーにすると RevenueCat が送り直し続けるため)。
func (r *RevenueCat) HandleEvent(event RevenueCatEvent, now time.Time) error {
	changes := premiumPlanChanges(event, r.EntitlementID, now)
	slog.Info("revenuecat webhook",
		slog.String("type", event.Type),
		slog.String("environment", event.Environment),
		slog.Int("changes", len(changes)))

	for userID, enable := range changes {
		if !database.IsValidUUID(userID) {
			// 匿名 ID ($RCAnonymousID:...) など、アプリのユーザー ID ではないもの
			continue
		}
		isExist, err := r.AWS.IsExistUser(userID)
		if err != nil {
			return err
		}
		if !isExist {
			slog.Warn("revenuecat webhook: unknown user", slog.String("type", event.Type))
			continue
		}
		if err := r.AWS.UpdateUserPremiumPlan(userID, enable); err != nil {
			return err
		}
	}
	return nil
}

// premiumPlanChanges はイベントから、どのユーザーのプレミアムプランを有効/無効にするかを返す。
func premiumPlanChanges(event RevenueCatEvent, entitlementID string, now time.Time) map[string]bool {
	switch event.Type {
	case "TEST":
		return nil
	case "TRANSFER":
		// 復元などで購入が別のユーザー ID に移った
		changes := map[string]bool{}
		for _, id := range event.TransferredFrom {
			changes[id] = false
		}
		for _, id := range event.TransferredTo {
			changes[id] = true
		}
		return changes
	case "EXPIRATION":
		if !slices.Contains(event.EntitlementIDs, entitlementID) {
			return nil
		}
		return map[string]bool{event.AppUserID: false}
	}

	// 購入・更新・解約 (期限までは有効)・返金 (期限が過去になる) など。期限で判断する
	if !slices.Contains(event.EntitlementIDs, entitlementID) {
		return nil
	}
	active := event.ExpirationAtMs == nil || time.UnixMilli(*event.ExpirationAtMs).After(now)
	return map[string]bool{event.AppUserID: active}
}
