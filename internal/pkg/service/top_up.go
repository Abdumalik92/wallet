package service

import "github.com/Abdumalik92/wallet/internal/pkg/repository"

func TopUp() error {
	return repository.TopUp()
}
