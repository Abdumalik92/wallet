package repository

import (
	"github.com/Abdumalik92/wallet/internal/db"
	"github.com/Abdumalik92/wallet/internal/models"
	"log"
)

func TopUp(request models.Request, response *models.Response) error {
	sqlQuery := `call top_up_wallet(?,?,?,null,null)`
	err := db.GetDBConn().Raw(sqlQuery, request.UserId, request.Phone, request.Amount).Scan(&response).Error
	if err != nil {
		log.Println("TopUp query err ", err.Error())
		return err
	}

	return nil
}
