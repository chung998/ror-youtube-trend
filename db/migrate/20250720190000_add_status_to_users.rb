class AddStatusToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :status, :string, default: 'active'
    add_column :users, :last_login_at, :datetime
    
    add_index :users, :status
    add_index :users, :last_login_at
  end
end 