package repository

import (
	"github.com/Abdumalik92/wallet/internal/db"
	"github.com/Abdumalik92/wallet/internal/models"
	"log"
)

func GetBalance(request models.Request, response *models.Response) error {
	sqlQuery := `select a.account_balance             p_balance,
					   u.phone                       p_phone,
					   case
						   when c.is_identified
							   then concat(c.s_name, ' ', c.name, ' ', c.patronymic)
						   else 'Not identified' end p_client_name
				from "user" u
						 inner join client c on u.id = c.user_id
						 inner join account a on c.id = a.client_id
				where u.id = ?;`
	err := db.GetDBConn().Raw(sqlQuery, request.UserId).Scan(&response).Error
	if err != nil {
		log.Println("GetBalance query err ", err.Error())
		return err
	}
	return nil
}
