package slashdeploy

import (
	"errors"

	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
)

// authenticate wraps the slash.Handler in middleware to authenticate the user
// frist, and set it in the context.
func authenticate(h slash.Handler, s UsersStore) slash.Handler {
	return slash.HandlerFunc(func(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
		user, err := s.Find(c.UserID)
		if err != nil {
			return slash.NoResponse, err
		}

		if user == nil {
			return slash.NoResponse, errors.New("not authenticated")
		}

		return h.ServeCommand(WithUser(ctx, user), r, c)
	})
}
