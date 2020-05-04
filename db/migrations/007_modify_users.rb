Sequel.migration do
	up do
		add_column :users, :imgpath, String, unique:true
	end
	down do
		drop_column :users, :imgpath
	end
end
