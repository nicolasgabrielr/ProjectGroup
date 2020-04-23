Sequel.migration do
  up do
    create_table(:documents) do
      primary_key :id
      File :document
      String :description
      String :date
    end
   end
   down do
     drop_table(:documents)
   end
end
