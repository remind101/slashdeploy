package slashdeploy

import (
	"database/sql"

	"golang.org/x/net/context"
)

// User represents a user for SlashDeploy.
type User struct {
	// Slack user id.
	ID string `db:"id"`

	// A GitHub access token.
	GitHubToken *string `db:"github_token"`
}

// Users service is a service for interacting with users in SlashDeploy.
type UsersService struct {
	*Client
}

// FindUser finds a user by id.
func (s *UsersService) FindUser(id string) (*User, error) {
	var user User
	err := s.db.Get(&user, `SELECT * FROM users WHERE id = $1 LIMIT 1`, id)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	return &user, err
}

// CreateUser creates a new user.
func (s *UsersService) CreateUser(user *User) error {
	_, err := s.db.NamedExec(`INSERT INTO users (id, github_token) VALUES (:id, :github_token)`, user)
	return err
}

// UserFromContext returns the embeded User object from the context.
func UserFromContext(ctx context.Context) (*User, bool) {
	u, ok := ctx.Value(userKey).(*User)
	return u, ok
}

// WithUser returns a new context with the User embeded.
func WithUser(ctx context.Context, user *User) context.Context {
	return context.WithValue(ctx, userKey, user)
}

type key int

const (
	userKey key = iota
)
