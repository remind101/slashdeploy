package users

import "github.com/ejholmes/slashdeploy"

// Service is a users service for fetching and creating users in SlashDeploy.
type Service struct {
	Users slashdeploy.UsersStore
}

// Find finds the user with the given id.
func (s *Service) Find(id string) (*slashdeploy.User, error) {
	return s.Users.Find(id)
}

// Save creates a new user.
func (s *Service) Save(user *slashdeploy.User) error {
	return s.Users.Save(user)
}
