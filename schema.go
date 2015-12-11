package slashdeploy

import (
	"github.com/jmoiron/sqlx"
	"github.com/rubenv/sql-migrate"
)

var Migrations = &migrate.AssetMigrationSource{
	Asset:    Asset,
	AssetDir: AssetDir,
	Dir:      "db/migrations",
}

// MigrateUp migrates the database up.
func MigrateUp(db *sqlx.DB, dialect string) error {
	_, err := migrate.Exec(db.DB, dialect, Migrations, migrate.Up)
	return err
}
