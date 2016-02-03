class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.string :repository
      t.string :name

      t.timestamps null: false
    end

    add_index :environments, [:repository, :name], unique: true
  end
end
