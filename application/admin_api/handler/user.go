package handler

import (
	"net/http"
	"strconv"

	"github.com/labstack/echo/v4"
	"github.com/takoikatakotako/charalarm/admin_api/service"
	"github.com/takoikatakotako/charalarm/admin_api/service/output"
)

const (
	defaultUsersLimit = 20
	maxUsersLimit     = 100
)

type User struct {
	Service service.User
}

type userIOSPlatformInfoResponse struct {
	PushToken                string `json:"pushToken"`
	PushTokenSNSEndpoint     string `json:"pushTokenSNSEndpoint"`
	VoIPPushToken            string `json:"voIPPushToken"`
	VoIPPushTokenSNSEndpoint string `json:"voIPPushTokenSNSEndpoint"`
}

type userResponse struct {
	UserID              string                      `json:"userID"`
	Platform            string                      `json:"platform"`
	PremiumPlan         bool                        `json:"premiumPlan"`
	CreatedAt           string                      `json:"createdAt"`
	UpdatedAt           string                      `json:"updatedAt"`
	RegisteredIPAddress string                      `json:"registeredIPAddress"`
	IOSPlatformInfo     userIOSPlatformInfoResponse `json:"iosPlatformInfo"`
}

type usersListResponse struct {
	Users      []userResponse `json:"users"`
	NextCursor string         `json:"nextCursor,omitempty"`
}

func (u *User) UsersGet(c echo.Context) error {
	limit := defaultUsersLimit
	if raw := c.QueryParam("limit"); raw != "" {
		if n, err := strconv.Atoi(raw); err == nil && n > 0 {
			if n > maxUsersLimit {
				n = maxUsersLimit
			}
			limit = n
		}
	}
	cursor := c.QueryParam("cursor")

	result, err := u.Service.ScanUsers(limit, cursor)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, newErrorResponse("scan_users_failed", err.Error()))
	}

	users := make([]userResponse, 0, len(result.Users))
	for _, user := range result.Users {
		users = append(users, toUserResponse(user))
	}

	return c.JSON(http.StatusOK, usersListResponse{
		Users:      users,
		NextCursor: result.NextCursor,
	})
}

func (u *User) UserGet(c echo.Context) error {
	userID := c.Param("userID")
	if userID == "" {
		return c.JSON(http.StatusBadRequest, newErrorResponse("invalid_user_id", "userID is required"))
	}

	user, err := u.Service.GetUser(userID)
	if err != nil {
		return c.JSON(http.StatusNotFound, newErrorResponse("user_not_found", err.Error()))
	}

	return c.JSON(http.StatusOK, toUserResponse(user))
}

func toUserResponse(u output.User) userResponse {
	return userResponse{
		UserID:              u.UserID,
		Platform:            u.Platform,
		PremiumPlan:         u.PremiumPlan,
		CreatedAt:           u.CreatedAt,
		UpdatedAt:           u.UpdatedAt,
		RegisteredIPAddress: u.RegisteredIPAddress,
		IOSPlatformInfo: userIOSPlatformInfoResponse{
			PushToken:                u.IOSPlatformInfo.PushToken,
			PushTokenSNSEndpoint:     u.IOSPlatformInfo.PushTokenSNSEndpoint,
			VoIPPushToken:            u.IOSPlatformInfo.VoIPPushToken,
			VoIPPushTokenSNSEndpoint: u.IOSPlatformInfo.VoIPPushTokenSNSEndpoint,
		},
	}
}
