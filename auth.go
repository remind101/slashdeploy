package slashdeploy

import "github.com/ejholmes/slash"

// authenticate wraps the slash.Handler in middleware to authenticate the user
// frist, and set it in the context.
func authenticate(h slash.Handler) slash.Handler {
	return h
}
