-- +migrate Up
CREATE TABLE environments (
  repository text NOT NULL,
  name text NOT NULL
);

CREATE UNIQUE INDEX index_environments_on_repo_and_name ON environments (repository, name);

-- +migrate Down
DROP TABLE environments;
