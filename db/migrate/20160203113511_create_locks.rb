class CreateLocks < ActiveRecord::Migration
  def change
    create_table :locks do |t|
      t.string :message
      t.boolean :active, default: false, null: false

      t.timestamps null: false
    end

    add_reference :locks, :environment, index: true
    add_index :locks, :environment_id, unique: true, name: 'locked_environment', where: 'active'
  end
end
