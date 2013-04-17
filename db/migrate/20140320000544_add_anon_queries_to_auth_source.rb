class AddAnonQueriesToAuthSource < ActiveRecord::Migration
  def change
    add_column :auth_sources, :anon_queries, :boolean
  end
end
