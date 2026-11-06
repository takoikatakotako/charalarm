package request

// Weather は /weather のリクエストボディ。
// 地域は URL に入れるとアクセスログに残るので、ボディで受け取る。
type Weather struct {
	// Region は都道府県コード ("01"〜"47")。
	Region string `json:"region"`
}
