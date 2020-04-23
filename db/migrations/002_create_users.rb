Sequel.migration do
	up do
		add_column :users, :surname, String, null: false
		add_column :users, :password, String, null:false
		add_column :users, :dni, Integer, null:false, unique:true
	end

	down do
		drop_column :users, :surname
		drop_column :users, :password
		drop_column :users, :dni
	end

end
