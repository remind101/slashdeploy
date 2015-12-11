package slashdeploy_test

import (
	"testing"

	"golang.org/x/net/context"

	"github.com/ejholmes/slashdeploy"
	"github.com/jmoiron/sqlx"
	_ "github.com/mattn/go-sqlite3"
	"github.com/stretchr/testify/assert"
)

func TestClient_CreateDeployment_CreatesEnvironment(t *testing.T) {
	c := newClient(t)
	defer c.Close()

	envs, err := c.ListEnvironments("ejholmes/acme-inc")
	assert.NoError(t, err)
	assert.Equal(t, 0, len(envs))

	ctx := slashdeploy.WithUser(context.Background(), &slashdeploy.User{})
	_, err = c.CreateDeployment(ctx, slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	})

	envs, err = c.ListEnvironments("ejholmes/acme-inc")
	assert.NoError(t, err)
	assert.Equal(t, 1, len(envs))

	env := envs[0]
	assert.Equal(t, "production", env.Name)

	_, err = c.CreateDeployment(ctx, slashdeploy.DeploymentRequest{
		Owner:       "ejholmes",
		Repository:  "acme-inc",
		Ref:         "master",
		Environment: "production",
	})
	assert.NoError(t, err)

	envs, err = c.ListEnvironments("ejholmes/acme-inc")
	assert.NoError(t, err)
	assert.Equal(t, 1, len(envs))
}

func newClient(t testing.TB) *slashdeploy.Client {
	db := sqlx.MustConnect("sqlite3", ":memory:")
	err := slashdeploy.MigrateUp(db, "sqlite3")
	if err != nil {
		t.Fatal(err)
	}

	c := slashdeploy.New(db)
	c.BuildDeployer = func(*slashdeploy.User) slashdeploy.Deployer {
		return slashdeploy.NullDeployer
	}
	return c
}
