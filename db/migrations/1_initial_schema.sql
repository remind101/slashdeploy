-- +migrate Up
CREATE TABLE users (
  id text NOT NULL primary key,
  github_token text
);

-- +migrate Down
DROP TABLE users;
