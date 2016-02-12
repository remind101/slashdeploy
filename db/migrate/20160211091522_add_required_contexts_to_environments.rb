class AddRequiredContextsToEnvironments < ActiveRecord::Migration
  def change
    add_column :environments, :required_contexts, :string, array: true
  end
end
