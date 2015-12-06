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

type key int

const (
	userKey key = iota
)

func UserFromContext(ctx context.Context) (*User, bool) {
	u, ok := ctx.Value(userKey).(*User)
	return u, ok
}

func WithUser(ctx context.Context, user *User) context.Context {
	return context.WithValue(ctx, userKey, user)
}

type UsersStore interface {
	Find(id string) (*User, error)
	Save(*User) error
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

func (u *usersStore) Save(user *User) error {
	u.Lock()
	defer u.Unlock()

	u.users[user.ID] = user
	return nil
}
