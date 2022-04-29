package controller

import (
	"github.com/Abdumalik92/wallet/internal/pkg/service"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

func TopUp(c *gin.Context) {
	err := service.TopUp()
	if err != nil {
		log.Println("TopUp controller err ", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"reason": "Something went wrong"})
		return
	}
	c.JSON(http.StatusOK, gin.H{"reason": "OK"})
}
