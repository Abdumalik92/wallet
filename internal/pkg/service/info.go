package service

import "github.com/Abdumalik92/wallet/internal/pkg/repository"

func GetInfo() error {
	return repository.GetInfo()
}
