package slack

import (
	"testing"

	"github.com/ejholmes/slash"
	"github.com/ejholmes/slashdeploy"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/net/context"
)

func Test_CommandNotFound(t *testing.T) {
	c := newHandler("token", new(mockClient))

	_, err := c.ServeCommand(context.Background(), nil, slash.Command{
		Command: "/foo",
	})
	assert.Equal(t, slash.ErrNoHandler, err)
}

func Test_InvalidToken(t *testing.T) {
	c := newHandler("token", new(mockClient))

	_, err := c.ServeCommand(context.Background(), nil, slash.Command{
		Command: "/deploy",
	})
	assert.Equal(t, slash.ErrInvalidToken, err)
}

func Test_Route(t *testing.T) {
	cmds := handlers{
		Help:         new(recordParamsHandler),
		Deploy:       new(recordParamsHandler),
		Environments: new(recordParamsHandler),
	}

	tests := []struct {
		text    string
		handler slash.Handler
		params  map[string]string
	}{
		{"help", cmds.Help, map[string]string{}},
		{"ejholmes/acme-inc", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc"}},
		{"ejholmes/acme-inc to staging", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "environment": "staging"}},
		{"ejholmes/acme-inc@topic-branch", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "ref": "topic-branch"}},
		{"ejholmes/acme-inc@topic-branch to staging", cmds.Deploy, map[string]string{"repo": "ejholmes/acme-inc", "ref": "topic-branch", "environment": "staging"}},
		{"where ejholmes/acme-inc?", cmds.Environments, map[string]string{"repo": "ejholmes/acme-inc"}},
		{"where ejholmes/acme-inc", cmds.Environments, map[string]string{"repo": "ejholmes/acme-inc"}},
	}

	for _, tt := range tests {
		h := tt.handler.(*recordParamsHandler)
		h.params = nil // Reset

		c := route("token", cmds)

		c.ServeCommand(context.Background(), nil, slash.Command{
			Token:   "token",
			Command: "/deploy",
			Text:    tt.text,
		})

		assert.Equal(t, tt.params, h.params)
	}
}

type recordParamsHandler struct {
	params map[string]string
}

func (m *recordParamsHandler) ServeCommand(ctx context.Context, r slash.Responder, c slash.Command) (slash.Response, error) {
	m.params = slash.Params(ctx)
	return slash.NoResponse, nil
}

type mockClient struct {
	mock.Mock
}

func (m *mockClient) CreateDeployment(ctx context.Context, request slashdeploy.DeploymentRequest) (*slashdeploy.Deployment, error) {
	args := m.Called(request)
	return args.Get(0).(*slashdeploy.Deployment), args.Error(1)
}

func (m *mockClient) ListEnvironments(repo string) ([]*slashdeploy.Environment, error) {
	args := m.Called(repo)
	return args.Get(0).([]*slashdeploy.Environment), args.Error(1)
}
