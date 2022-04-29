package service

import "github.com/Abdumalik92/wallet/internal/pkg/repository"

func GetBalance() error {

	return repository.GetBalance()
}
