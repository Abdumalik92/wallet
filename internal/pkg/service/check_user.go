package service

import "github.com/Abdumalik92/wallet/internal/pkg/repository"

func CheckUser(userId int64) error {
	err := repository.CheckUser(userId)
	if err != nil {
		return err
	}
	return nil
}
