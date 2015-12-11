package slashdeploy

import "github.com/jmoiron/sqlx"

// Client is a primary client to performing actions in SlashDeploy.
type Client struct {
	Users       *UsersService
	Deployments *DeploymentsService

	// BuildDeployer is a function that will be called to return a Deployer
	// instance that can be used to create the deployment as the given user.
	BuildDeployer func(*User) Deployer

	db *sqlx.DB
}

// New builds a new Client instance.
func New(db *sqlx.DB) *Client {
	c := &Client{db: db}
	c.Users = newUsersService(c)
	c.Deployments = newDeploymentsService(c)
	return c
}

// Close closes the db connection.
func (c *Client) Close() error {
	return c.db.Close()
}
