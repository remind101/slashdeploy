package auth

import (
	"errors"
	"fmt"
	"io"
	"net/http"

	"github.com/dgrijalva/jwt-go"
	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

type authenticate struct {
	URL string
}

func (e *authenticate) Error() string {
	return fmt.Sprintf("Please <%s|authenticate> then try again.", e.URL)
}

// Authenticator handles oauth authentication for the commands. If the slack
// user is not found in the users store, it generates a link for the user to
// initiate an oauth flow with the provider.
type Authenticator struct {
	slash.Handler
	Users slashdeploy.UsersStore
	StateEncoder

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
		state, err := h.Encode(State{
			UserID: c.UserID,
		})
		if err != nil {
			return slash.NoResponse, err
		}

		url := h.AuthCodeURL(state)
		return slash.NoResponse, &authenticate{URL: url}
	}

	// Add the user to the context for downstream consumers.
	ctx = slashdeploy.WithUser(ctx, user)

	return h.Handler.ServeCommand(ctx, r, c)
}

// GitHubAuthCallback is an http.Handler that creates a new user.
type GitHubAuthCallback struct {
	Users slashdeploy.UsersStore
	StateDecoder
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

	state, err := h.Decode(r.FormValue("state"))
	if err != nil {
		return err
	}

	if err := h.Users.Save(&slashdeploy.User{
		ID:          state.UserID,
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

// State is passed during the oauth flow to keep track of the user id.
type State struct {
	UserID string
}

type StateEncoder interface {
	Encode(State) (string, error)
}

type StateDecoder interface {
	Decode(state string) (*State, error)
}

func SignedState(key []byte) *jwtState {
	return &jwtState{key: key}
}

// jwtState encodes and decodes State's using JWT.
type jwtState struct {
	key []byte
}

func (s *jwtState) Encode(state State) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)
	token.Claims["user_id"] = state.UserID
	return token.SignedString(s.key)
}

func (s *jwtState) Decode(state string) (*State, error) {
	token, err := jwt.Parse(state, jwtStaticKey(s.key))
	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, errors.New("invalid state")
	}

	return &State{
		UserID: token.Claims["user_id"].(string),
	}, nil

}

func jwtStaticKey(secret []byte) func(*jwt.Token) (interface{}, error) {
	return func(*jwt.Token) (interface{}, error) {
		return secret, nil
	}
}
