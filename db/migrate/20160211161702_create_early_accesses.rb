class CreateEarlyAccesses < ActiveRecord::Migration
  def change
    create_table :early_accesses, id: false do |t|
      t.string :email, null: false

      t.timestamps null: false
    end
  end
end
