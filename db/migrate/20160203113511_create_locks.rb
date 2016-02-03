class CreateLocks < ActiveRecord::Migration
  def change
    create_table :locks do |t|
      t.string :message
      t.boolean :active, default: false, null: false

      t.timestamps null: false
    end

    add_reference :locks, :environment, index: true
    add_foreign_key :locks, :environment
    add_index :locks, [:environment_id, :active], unique: true, where: 'active'
  end
end
