Sequel.migration do
	up do
		add_column :users, :email, String, null:false, unique:true
		add_column :users, :username, String, null:false,  unique:true
		add_column :users, :category, String
	end
	down do
		drop_column :users, :email
		drop_column :users, :username
		drop_column :users, :category
	end
end
