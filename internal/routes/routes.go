package routes

import (
	"fmt"
	"github.com/Abdumalik92/wallet/internal/middlware"
	"github.com/Abdumalik92/wallet/internal/pkg/controller"
	"github.com/Abdumalik92/wallet/internal/pkg/utils"
	"github.com/gin-gonic/gin"
	"gopkg.in/natefinch/lumberjack.v2"
	"io"
	"log"
	"os"
)

func RunAllRoutes() {
	r := gin.Default()
	r.Use(CORSMiddleware())

	f, err := os.OpenFile(utils.AppSettings.AppParams.LogFile, os.O_APPEND|os.O_WRONLY|os.O_CREATE, 0666)

	if err != nil {
		fmt.Println("file create error", err.Error())
		return
	}

	logger := &lumberjack.Logger{
		Filename:   f.Name(),
		MaxSize:    10, // megabytes
		MaxBackups: 100,
		MaxAge:     28,   // days
		Compress:   true, // disabled by default
	}

	log.SetOutput(logger)
	gin.DefaultWriter = io.MultiWriter(logger, os.Stdout)

	r.GET("/info", middlware.CheckUser, controller.GetInfo)
	r.POST("/top_up", middlware.CheckUser, controller.TopUp)
	r.GET("/operation", middlware.CheckUser, controller.GetOperation)
	r.GET("/balance", middlware.CheckUser, controller.GetBalance)

	_ = r.Run(utils.AppSettings.AppParams.PortRun)
}
