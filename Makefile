cmd::
	godep go build -o build/slashdeploy ./cmd/slashdeploy

db::
	dropdb slashdeploy || true
	createdb slashdeploy || true
	psql -f schema.sql slashdeploy
