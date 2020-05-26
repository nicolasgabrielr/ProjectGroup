class Document < Sequel::Model
  plugin :validation_helpers
  def validate
   super
    validates_presence [:resolution, :filename, :path, :realtime]
    validates_unique [:resolution, :filename, :path, :realtime]
  end
  dataset_module do
    def deleteds(true_or_false)
      select(:filename, :resolution, :realtime).
      where(deleted: true_or_false).
      all
    end
    def by_resolution(resolution)
      select(:filename, :resolution, :realtime).
      where(resolution: resolution, deleted: false).
      all
    end
    def by_date(initial_date, final_date)
      select(:filename, :resolution, :realtime).
      where(realtime: initial_date..final_date, deleted: false).
      all
    end
    def by_date_and_user(initial_date, final_date, user)
      select(:filename, :resolution, :realtime).
      where(realtime: initial_date..final_date, user_id: user, deleted: false).
      all
    end
  end
  many_to_many :users
  one_to_many :notifications
end
