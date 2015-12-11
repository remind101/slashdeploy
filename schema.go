package slashdeploy

const Schema = `
CREATE TABLE users (
  id text NOT NULL primary key,
  github_token text
);
`
