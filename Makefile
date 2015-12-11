cmd::
	godep go build -o build/slashdeploy ./cmd/slashdeploy

db::
	dropdb slashdeploy || true
	createdb slashdeploy || true

migrations::
	go-bindata -pkg slashdeploy -o bindata.go db/migrations/
