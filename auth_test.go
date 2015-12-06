package slashdeploy

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ejholmes/slash"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

func TestAuthenticator_ServeCommand(t *testing.T) {
	u := new(mockUsersStore)
	a := &Authenticator{
		Users:  u,
		Config: &oauth2.Config{},
	}

	u.On("Find", "T1").Return(nil, nil)

	_, err := a.ServeCommand(context.Background(), nil, slash.Command{
		UserID: "T1",
	})
	assert.IsType(t, &authorize{}, err)
}

func TestGitHubAuthCallback(t *testing.T) {
	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"access_token":"abcd"}`)
	}))
	defer s.Close()

	u := new(mockUsersStore)
	h := &GitHubAuthCallback{
		Users: u,
		Config: &oauth2.Config{
			Endpoint: oauth2.Endpoint{
				TokenURL: s.URL,
			},
		},
	}

	req, _ := http.NewRequest("GET", "?code=1234&state=T1", nil)
	resp := httptest.NewRecorder()

	u.On("Save", &User{
		ID:          "T1",
		GitHubToken: "abcd",
	}).Return(nil)

	h.ServeHTTP(resp, req)

	t.Log(resp.Body.String())
	assert.Equal(t, http.StatusOK, resp.Code)
}

type mockUsersStore struct {
	mock.Mock
}

func (m *mockUsersStore) Find(id string) (*User, error) {
	args := m.Called(id)
	u, ok := args.Get(0).(*User)
	if !ok {
		return nil, args.Error(1)
	}
	return u, args.Error(1)
}

func (m *mockUsersStore) Save(user *User) error {
	args := m.Called(user)
	return args.Error(0)
}
