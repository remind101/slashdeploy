package slashdeploy

import (
	"sync"

	"golang.org/x/net/context"
)

type User struct {
	// Slack user id.
	ID string

	// A GitHub access token.
	GitHubToken string
}

func UserFromContext(ctx context.Context) (*User, bool) {
	return nil, false
}

func WithUser(ctx context.Context, user *User) context.Context {
	return ctx
}

type UsersStore interface {
	Find(id string) (*User, error)
}

// in memory usersStore.
type usersStore struct {
	sync.RWMutex
	users map[string]*User
}

func (u *usersStore) Find(id string) (*User, error) {
	u.RLock()
	defer u.RUnlock()

	return u.users[id], nil
}
