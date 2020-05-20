Sequel.migration do
	up do
		rename_column :documents, :fk_users_id, :user_id
		drop_column :documents, :document
		drop_column :documents, :date
	end
	down do
		rename_column :documents_users, :user_id, :fk_users_id
		add_column :documents, :document
		add_column :documents, :date
	end
end
