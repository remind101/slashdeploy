package slashdeploy

// Environment represents a known environment for a repo.
type Environment struct {
	Repository string

	// Name of the environment.
	Name string
}

type EnvironmentsService struct {
	*Client
}

func (s *EnvironmentsService) ListEnvironments(fullRepoName string) ([]*Environment, error) {
	var envs []*Environment
	err := s.db.Select(&envs, `SELECT * FROM environments WHERE repository = $1`, fullRepoName)
	return envs, err
}

func (s *EnvironmentsService) CreateEnvironment(env *Environment) error {
	_, err := s.db.NamedExec(`INSERT INTO environments (repository, name) VALUES (:repository, :name)`, env)
	return err
}
