Sequel.migration do
	up do
		add_column :documents, :deleted, "boolean"
		set_column_default :documents, :deleted, false
	end
	down do
		drop_column :documents, :deleted
	end
end
