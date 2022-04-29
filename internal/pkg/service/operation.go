package service

import "github.com/Abdumalik92/wallet/internal/pkg/repository"

func GetOperation() error {
	return repository.GetOperation()
}
