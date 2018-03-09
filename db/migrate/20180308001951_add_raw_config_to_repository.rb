class AddRawConfigToRepository < ActiveRecord::Migration
  def change
    add_column :repositories, :raw_config, :text
  end
end
