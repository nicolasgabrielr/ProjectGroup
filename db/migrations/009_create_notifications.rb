Sequel.migration do
	up do
		create_table(:documents_users) do
			foreign_key :document_id, :documents, :null=>false
		  foreign_key :user_id, :users, :null=>false
		  primary_key [:document_id, :user_id]
		  index [:document_id, :user_id]
	 end
 end
	 down do
		 drop_table :documents_users
	 end
end
