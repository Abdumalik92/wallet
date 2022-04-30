package repository

import (
	"github.com/Abdumalik92/wallet/internal/db"
	"github.com/Abdumalik92/wallet/internal/models"
	"log"
)

func GetOperation(request models.Request, response *models.Response) error {
	sqlQuery := `select sum(co) p_count, sum(su) p_sum
from (select count(tr.id) co, sum(tr.amount) su
      from transaction tr
               inner join account a on a.id = tr.account_from
               inner join client c on c.id = a.client_id
               inner join "user" u on u.id = c.user_id
      where u.id = ?
        and tr.create_date >= date_trunc('month', now())
        and tr.create_date < date_trunc('month', now() + interval '1 month')
      union
      select count(tr.id) co, sum(tr.amount) su
      from transaction tr
               inner join account a on a.id = tr.account_to
               inner join client c on c.id = a.client_id
               inner join "user" u on u.id = c.user_id
      where u.id = ?
        and tr.create_date >= date_trunc('month', now())
        and tr.create_date < date_trunc('month', now() + interval '1 month')
     ) foo;`
	err := db.GetDBConn().Raw(sqlQuery, request.UserId, request.UserId).Scan(&response).Error
	if err != nil {
		log.Println("GetOperation query err ", err.Error())
		return err
	}
	return nil
}
