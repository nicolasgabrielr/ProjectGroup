Sequel.migration do
	up do
		add_column :documents, :path, String, null:false, unique:true
	end
	down do
		drop_column :documents, :path
	end
end
