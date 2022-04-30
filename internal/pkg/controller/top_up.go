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

func TopUp(c *gin.Context) {
	var (
		request  models.Request
		response models.Response
	)
	userId, err := strconv.ParseInt(c.GetHeader("X-UserId"), 10, 64)
	if err != nil {
		log.Println("TopUp parse user_id error ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Something went wrong"})
		return
	}
	hash := c.GetHeader("X-Digest")

	err = c.ShouldBindJSON(&request)
	if err != nil {
		log.Println("TopUp bind json error ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Something went wrong"})
		return
	}
	request.UserId = userId

	checkHash := utils.GetSha256(fmt.Sprint(request.UserId)+request.Phone+fmt.Sprint(request.Amount), []byte(utils.AppSettings.SecretKey.Key))
	log.Println(checkHash)
	if checkHash != hash {
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Invalid hash"})
		return
	}

	log.Printf("TopUp userID %d request = %v", request.UserId, request)

	err = service.TopUp(request, &response)
	if err != nil {
		log.Println("TopUp controller err ", err.Error())
		c.JSON(http.StatusInternalServerError, gin.H{"reason": "Something went wrong"})
		return
	}
	if response.Code == 2 {
		c.JSON(http.StatusInternalServerError, gin.H{"reason": "Something went wrong"})
		return
	}
	if response.Code == 1 {
		c.JSON(http.StatusBadRequest, gin.H{"reason": response.Message})
		return
	}

	c.JSON(http.StatusOK, response)
}
