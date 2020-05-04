Sequel.migration do
	up do
		add_column :documents, :filename, String, null:false, unique:true
        add_column :documents, :resolution, String, null:false, unique:true
        add_column :documents, :realtime, 'timestamp with time zone', null:false, unique:true
	end
	down do
		drop_column :documents, :filename
        drop_column :documents, :resolution
        drop_column :documents, :realtime
	end
end


