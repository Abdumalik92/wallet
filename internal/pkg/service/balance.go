package service

import (
	"github.com/Abdumalik92/wallet/internal/models"
	"github.com/Abdumalik92/wallet/internal/pkg/repository"
)

func GetBalance(request models.Request, response *models.Response) error {

	return repository.GetBalance(request, response)
}
