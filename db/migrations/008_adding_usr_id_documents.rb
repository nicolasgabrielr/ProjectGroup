Sequel.migration do
	up do
		alter_table(:documents) do
			add_foreign_key :fk_users_id, :users
		end
	end
	down do
		alter_table(:documents) do
			drop_foreign_key :fk_users_id
		end
	end
end

	#up do
	#	create_join_table(documents_id: :documents, users_id: :users)
	#	 from(:documents_users).insert([:documents_id, :users_id],
    #		from(:documents).select(:id, :users_id).exclude(users_id: nil))
	#	 drop_column :documents, :users_id
	#end
	#down do
	#	alter_table :documents{add_foreign_key :fk_users_id, :users}
	#	from(:documents).update(users_id: from(:documents_user).
	#      select{max(users_id)}.
	#      where(documents_id: Sequel[:documents][:id]))
	#    # Drop the albums_artists table
	#   	drop_join_table(fk_users_id: :documents)
	#end

