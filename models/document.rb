class Document < Sequel::Model
  plugin :validation_helpers
  def validate
   super
    validates_presence [:resolution, :filename, :path, :realtime]
    validates_unique [:resolution, :filename, :path, :realtime]
  end
  many_to_many :users
  one_to_many :notifications
  set_primary_key :id
end
