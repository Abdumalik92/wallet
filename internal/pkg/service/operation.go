package service

import (
	"github.com/Abdumalik92/wallet/internal/models"
	"github.com/Abdumalik92/wallet/internal/pkg/repository"
)

func GetOperation(request models.Request, response *models.Response) error {
	return repository.GetOperation(request, response)
}
