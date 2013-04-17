class CreateExternalUsergroups < ActiveRecord::Migration
  def change
    create_table :external_usergroups do |t|
      t.string  :name,           :null => false
      t.integer :auth_source_id, :null => false
      t.integer :usergroup_id,   :null => false
    end

    add_index :external_usergroups, :usergroup_id
  end
end
