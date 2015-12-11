package slashdeploy

import (
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
)

func newTestClient() *Client {
	db := sqlx.MustConnect("sqlite3", ":memory:")
	if err := MigrateUp(db, "sqlite3"); err != nil {
		panic(err)
	}
	return New(db)
}
