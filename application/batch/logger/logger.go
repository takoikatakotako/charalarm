package logger

import (
	"log/slog"
	"os"
)

func Info(msg string, fileName string, funcName string, line int) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	logger.Info(msg)
}

func Warn(msg string, fileName string, funcName string, line int) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	logger.Warn(msg, "FileName", fileName, "FuncName", funcName, "Line", line)
}

func Error(msg string, fileName string, funcName string, line int) {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, nil))
	logger.Error(msg)
}
