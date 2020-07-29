.DEFAULT_GOAL := build

.PHONY: build
build:
	docker-compose build

.PHONY: test
test:
	docker-compose run --rm test rake

.PHONY: shell
shell:
	docker-compose run --rm test bash

.PHONY: ngrok
ngrok:
	ngrok start -config=./ngrok.yml default

.PHONY: dev
dev:
	docker-compose run --rm --service-ports dev

.PHONY: psql
psql:
	docker-compose run --rm test psql -h postgres -U postgres

.PHONY: reset
reset:
	docker-compose stop
	docker-compose rm
