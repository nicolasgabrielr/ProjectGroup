Sequel.migration do
	up do
		add_column :documents_users, :check, "boolean"
		set_column_default :documents_users, :check, false

	end
	down do
		drop_column :documents_users, :check
	end
end
