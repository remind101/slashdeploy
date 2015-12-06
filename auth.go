package slashdeploy

import (
	"fmt"
	"io"
	"net/http"

	"github.com/ejholmes/slash"
	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

type authorize struct {
	URL string
}

func (e *authorize) Error() string {
	return fmt.Sprintf("Please <%s|authenticate> then try again.", e.URL)
}

// Authenticator handles oauth authentication for the commands. If the slack
// user is not found in the users store, it generates a link for the user to
// initiate an oauth flow with the provider.
type Authenticator struct {
	slash.Handler
	Users UsersStore

	*oauth2.Config
}

func (h *Authenticator) ServeCommand(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
	user, err := h.Users.Find(c.UserID)
	if err != nil {
		return slash.NoResponse, err
	}

	// If the user doesn't exist, give them a url to oauth with the
	// provider.
	if user == nil {
		url := h.AuthCodeURL(c.UserID)
		return slash.NoResponse, &authorize{URL: url}
	}

	// Add the user to the context for downstream consumers.
	ctx = WithUser(ctx, user)

	return h.Handler.ServeCommand(ctx, r, c)
}

// GitHubAuthCallback is an http.Handler that creates a new user.
type GitHubAuthCallback struct {
	Users UsersStore
	*oauth2.Config
}

func (h *GitHubAuthCallback) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if err := h.exchange(r); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	io.WriteString(w, "Ok")
}

func (h *GitHubAuthCallback) exchange(r *http.Request) error {
	token, err := h.Exchange(oauth2.NoContext, r.FormValue("code"))
	if err != nil {
		return err
	}

	userID := r.FormValue("state")

	if err := h.Users.Save(&User{
		ID:          userID,
		GitHubToken: token.AccessToken,
	}); err != nil {
		return err
	}

	return nil
}

type SlackAuthCallback struct {
	*oauth2.Config
}

func (h *SlackAuthCallback) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if err := h.exchange(r); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	http.Redirect(w, r, "/", http.StatusTemporaryRedirect)
}

func (h *SlackAuthCallback) exchange(r *http.Request) error {
	code := r.FormValue("code")

	token, err := h.Exchange(oauth2.NoContext, code)
	if err != nil {
		return err
	}

	if err, ok := token.Extra("error").(string); ok {
		return fmt.Errorf(err)
	}

	return nil
}
