package slashdeploy

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestUsersService_FindUser(t *testing.T) {
	c := newTestClient()
	defer c.Close()

	s := c.Users

	user, err := s.FindUser("1")
	assert.NoError(t, err)
	assert.Nil(t, user)

	c.db.MustExec(`INSERT INTO users (id) VALUES ('1')`)

	user, err = s.FindUser("1")
	assert.NoError(t, err)
	assert.Equal(t, &User{ID: "1"}, user)
}

func TestUsersService_CreateUser(t *testing.T) {
	c := newTestClient()
	defer c.Close()

	s := &UsersService{
		Client: c,
	}

	err := s.CreateUser(&User{ID: "1"})
	assert.NoError(t, err)

	err = s.CreateUser(&User{ID: "1"})
	assert.Error(t, err)
}
