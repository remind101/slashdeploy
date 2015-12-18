package auth

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

func TestAuthenticator_ServeCommand(t *testing.T) {
	u := new(mockUsersService)
	a := &Authenticator{
		Users:        u,
		Config:       &oauth2.Config{},
		StateEncoder: new(nullState),
	}

	u.On("FindUser", "T1").Return(nil, nil)

	err := a.ServeCommand(context.Background(), nil, slash.Command{
		UserID: "T1",
	})
	assert.IsType(t, &authenticate{}, err)
}

func TestGitHubAuthCallback(t *testing.T) {
	s := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		io.WriteString(w, `{"access_token":"abcd"}`)
	}))
	defer s.Close()

	u := new(mockUsersService)
	h := &GitHubAuthCallback{
		Users:        u,
		StateDecoder: new(nullState),
		Config: &oauth2.Config{
			Endpoint: oauth2.Endpoint{
				TokenURL: s.URL,
			},
		},
	}

	req, _ := http.NewRequest("GET", "?code=1234&state=T1", nil)
	resp := httptest.NewRecorder()

	token := "abcd"
	u.On("CreateUser", &slashdeploy.User{
		ID:          "T1",
		GitHubToken: &token,
	}).Return(nil)

	h.ServeHTTP(resp, req)

	t.Log(resp.Body.String())
	assert.Equal(t, http.StatusOK, resp.Code)
}

func TestJWTState(t *testing.T) {
	s := &jwtState{key: []byte{'a', 'b', 'c'}}

	str, err := s.Encode(State{
		UserID: "T1",
	})
	assert.NoError(t, err)

	state, err := s.Decode(str)
	assert.NoError(t, err)
	assert.Equal(t, "T1", state.UserID)
}

type mockUsersService struct {
	mock.Mock
}

func (m *mockUsersService) FindUser(id string) (*slashdeploy.User, error) {
	args := m.Called(id)
	u, ok := args.Get(0).(*slashdeploy.User)
	if !ok {
		return nil, args.Error(1)
	}
	return u, args.Error(1)
}

func (m *mockUsersService) CreateUser(user *slashdeploy.User) error {
	args := m.Called(user)
	return args.Error(0)
}

type nullState struct{}

func (s *nullState) Encode(state State) (string, error) {
	return state.UserID, nil
}

func (s *nullState) Decode(state string) (*State, error) {
	return &State{
		UserID: state,
	}, nil
}
