Rails.application.routes.draw do
  post '/auth/developer/callback' => 'github#callback'
  get '/auth/github/callback' => 'github#callback'
  get '/auth/slack/callback' => 'slack#callback'

  get '/slack/installed' => 'slack#installed', as: :installed
  get '/slack/install' => 'slack#install', as: :install
  post '/slack/install' => 'slack#early_access', as: :early_access

  get '/*id/edit' => 'repositories#edit', constraints: { id: SlashDeploy::GITHUB_REPO_REGEX }, as: :repository_edit
  patch '/*id' => 'repositories#update', constraints: { id: SlashDeploy::GITHUB_REPO_REGEX }, as: :repository

  get '/*repository_id/environments/:id/edit' => 'environments#edit', constraints: { repository_id: SlashDeploy::GITHUB_REPO_REGEX }, as: :repository_environment_edit
  patch '/*repository_id/environments/:id' => 'environments#update', constraints: { repository_id: SlashDeploy::GITHUB_REPO_REGEX }, as: :repository_environment

  # Docs
  get '/docs' => 'documentation#index', as: :documentation

  mount SlashDeploy::Commands.slack, at: '/commands'
  post '/', to: SlashDeploy.github_webhooks, constraints: Hookshot.constraint

  root 'pages#index'
end
