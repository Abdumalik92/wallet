package middlware

import (
	"github.com/Abdumalik92/wallet/internal/pkg/service"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
	"strconv"
)

func CheckUser(c *gin.Context) {

	userId, err := strconv.ParseInt(c.GetHeader("X-UserId"), 10, 64)
	if err != nil {
		log.Println("CheckUser parse user_id error ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Something went wrong"})
		c.Abort()
		return
	}

	if err = service.CheckUser(userId); err != nil {
		log.Println("CheckUser ExitsUser error ", err.Error())
		c.JSON(http.StatusBadRequest, gin.H{"reason": "Something went wrong"})
		c.Abort()
		return
	}
}
