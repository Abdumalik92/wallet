package controller

import (
	"github.com/Abdumalik92/wallet/internal/pkg/service"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

func GetBalance(c *gin.Context) {
	err := service.GetBalance()
	if err != nil {
		log.Println("GetBalance controller err ", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"reason": "Something went wrong"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"reason": "OK"})
}
