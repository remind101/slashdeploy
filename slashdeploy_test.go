package slashdeploy

import (
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
)

func newTestClient() *Client {
	db := sqlx.MustConnect("sqlite3", ":memory:")
	db.MustExec(Schema)
	return New(db)
}
