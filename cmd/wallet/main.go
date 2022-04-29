package main

import (
	"github.com/Abdumalik92/wallet/internal/db"
	"github.com/Abdumalik92/wallet/internal/pkg/utils"
	"github.com/Abdumalik92/wallet/internal/routes"
)

func main() {
	utils.ReadSettings()

	db.StartDbConnection()

	routes.RunAllRoutes()
}
