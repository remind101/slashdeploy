package github

import (
	"net/http"
	"testing"

	"github.com/ejholmes/slashdeploy/deployments"
	"github.com/google/go-github/github"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
	"golang.org/x/net/context"
)

func TestDeployer_Deploy(t *testing.T) {
	g := new(mockGitHubClient)
	s := Deployer{
		github: g,
	}

	g.On("CreateDeployment", "ejholmes", "acme-inc", &github.DeploymentRequest{
		Environment: github.String("production"),
		Ref:         github.String("master"),
		AutoMerge:   github.Bool(false),
		Task:        github.String("deploy"),
	}).Return(&github.Deployment{ID: github.Int(1)}, nil)

	_, err := s.Deploy(context.Background(), deployments.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Environment: "production",
		Ref:         "master",
	})
	assert.NoError(t, err)
}

func TestDeployer_Deploy_CommitStatusChecksFailed(t *testing.T) {
	g := new(mockGitHubClient)
	s := Deployer{
		github: g,
	}

	req, _ := http.NewRequest("POST", "https://api.github.com/repos/ejholmes/acme-inc/deployments", nil)
	g.On("CreateDeployment", "ejholmes", "acme-inc", &github.DeploymentRequest{
		Environment: github.String("production"),
		Ref:         github.String("master"),
		AutoMerge:   github.Bool(false),
		Task:        github.String("deploy"),
	}).Return(&github.Deployment{}, &github.ErrorResponse{
		Response: &http.Response{
			Request: req,
		},
		Message: "Conflict: Commit status checks failed for",
		Errors: []github.Error{
			{
				Resource: "Deployment",
				Field:    "required_contexts",
				Code:     "invalid",
			},
		},
	})

	_, err := s.Deploy(context.Background(), deployments.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Environment: "production",
		Ref:         "master",
	})
	assert.IsType(t, &CommitStatusChecksError{}, err)
}

func TestDeployer_Deploy_NoRef(t *testing.T) {
	g := new(mockGitHubClient)
	s := Deployer{
		github: g,
	}

	req, _ := http.NewRequest("POST", "https://api.github.com/repos/ejholmes/acme-inc/deployments", nil)
	g.On("CreateDeployment", "ejholmes", "acme-inc", &github.DeploymentRequest{
		Environment: github.String("production"),
		Ref:         github.String("master"),
		AutoMerge:   github.Bool(false),
		Task:        github.String("deploy"),
	}).Return(&github.Deployment{}, &github.ErrorResponse{
		Response: &http.Response{
			Request: req,
		},
		Message: "No ref found for",
		Errors:  []github.Error{},
	})

	_, err := s.Deploy(context.Background(), deployments.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Environment: "production",
		Ref:         "master",
	})
	assert.IsType(t, &NoRefError{}, err)
}

type mockGitHubClient struct {
	mock.Mock
}

func (m *mockGitHubClient) CreateDeployment(owner, repo string, request *github.DeploymentRequest) (*github.Deployment, *github.Response, error) {
	args := m.Called(owner, repo, request)
	return args.Get(0).(*github.Deployment), nil, args.Error(1)
}
