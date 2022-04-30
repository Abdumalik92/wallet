package repository

import (
	"errors"
	"github.com/Abdumalik92/wallet/internal/db"
	"github.com/Abdumalik92/wallet/internal/models"
	"log"
)

func CheckUser(userId int64) error {
	var count int64
	sqlQuery := `select count(1)
				 from "user" u
				 where u.id = ?;`
	err := db.GetDBConn().Raw(sqlQuery, userId).Count(&count).Error
	if err != nil {
		log.Println("CheckUser query err ", err.Error())
		return err
	}
	if count == 0 {
		log.Println("CheckUser user not found")
		return errors.New("You're not our client")
	}

	sqlQuery = `select count(1)
				 from "user" u
				 where u.id = ? and is_active = true;`
	err = db.GetDBConn().Raw(sqlQuery, userId).Count(&count).Error
	if err != nil {
		log.Println("CheckUser query err ", err.Error())
		return err
	}
	if count == 0 {
		log.Println("IsOurUser account is not active")
		return errors.New("Your account is not active")
	}
	return nil
}

func GetInfo(request models.Request, response *models.Response) error {
	sqlQuery := `select case
							   when c.is_identified
								   then concat(c.s_name, ' ', c.name, ' ', c.patronymic)
							   else 'Not identified' end p_client_name,
						   u.phone                       p_phone,
                           u.is_active 					 p_status
					from "user" u
							 inner join client c on u.id = c.user_id
					where u.phone = ?;`
	err := db.GetDBConn().Raw(sqlQuery, request.Phone).Scan(&response).Error
	if err != nil {
		log.Println("GetInfo query err ", err.Error())
		return err
	}

	if response.Status == false {
		response.Message = "Client account is not active"
		return nil
	}

	if response.Phone == "" {
		response.Message = "Client not found"
		return nil
	}
	return nil
}
