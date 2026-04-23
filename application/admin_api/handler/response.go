package handler

type ErrorResponse struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func newErrorResponse(code, message string) ErrorResponse {
	return ErrorResponse{Code: code, Message: message}
}
