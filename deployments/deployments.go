package deployments

type Deployment struct {
	// A unique identifier for the deployment request that was created.
	ID string
}

type DeploymentRequest struct {
	// The User or Organization that owns the repository.
	Owner string

	// The name of the repository to deploy.
	Repository string

	// The git ref to deploy.
	Ref string

	// The environment to deploy to.
	Environment string
}

type DeploymentEvent int

const (
	EventPending DeploymentEvent = iota
	EventStarted
	EventSucceeded
	EventFailed
)

type Event struct {
	Event DeploymentEvent
}

// Deployer represents something that can create deployment requests.
type Deployer interface {
	// When deploy is called, the implementer should create a deployment
	// request then immediately return. The implementer can use the provided
	// Events to notify the consumer about status updates.
	Deploy(DeploymentRequest, Events) (*Deployment, error)
}

type DeployerFunc func(DeploymentRequest, Events) (*Deployment, error)

func (fn DeployerFunc) Deploy(req DeploymentRequest, u Events) (*Deployment, error) {
	return fn(req, u)
}

type Events interface {
	Event(Event) error
}

// NullDeployer is a Deployer implementation that does nothing.
var NullDeployer = DeployerFunc(func(req DeploymentRequest, e Events) (*Deployment, error) {
	return &Deployment{ID: "1"}, nil
})
