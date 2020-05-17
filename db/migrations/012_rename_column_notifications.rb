Sequel.migration do
	up do
		rename_column :documents_users, :check, :checked
	end
	down do
		rename_column :documents_users, :checked, :check
	end
end
