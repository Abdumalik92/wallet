package controller

import (
	"fmt"
	"github.com/Abdumalik92/wallet/internal/models"
	"github.com/Abdumalik92/wallet/internal/pkg/service"
	"github.com/Abdumalik92/wallet/internal/pkg/utils"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"strconv"
)

func GetBalance(c *gin.Context) {
	var (
		request  models.Request
		response models.Response
	)
	userId, err := strconv.ParseInt(c.GetHeader("X-UserId"), 10, 64)
	if err != nil {
		log.Println("GetBalance parse user_id error ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Something went wrong"})
		return
	}
	hash := c.GetHeader("X-Digest")

	request.UserId = userId

	checkHash := utils.GetSha256(fmt.Sprint(request.UserId), []byte(utils.AppSettings.SecretKey.Key))

	if checkHash != hash {
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Invalid hash"})
		return
	}

	log.Printf("GetBalance userID %d request = %v", request.UserId, request)

	err = service.GetBalance(request, &response)
	if err != nil {
		log.Println("GetBalance controller err ", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"reason": "Something went wrong"})
		return
	}
	c.JSON(http.StatusOK, response)
}
