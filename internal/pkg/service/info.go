package service

import (
	"github.com/Abdumalik92/wallet/internal/models"
	"github.com/Abdumalik92/wallet/internal/pkg/repository"
)

func GetInfo(request models.Request, response *models.Response) error {
	return repository.GetInfo(request, response)
}
