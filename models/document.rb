class Document < Sequel::Model
  plugin :validation_helpers
  def validate
   super
    validates_presence [:resolution, :filename, :path, :realtime]
    validates_unique [:resolution, :filename, :path, :realtime]
  end
  dataset_module do
    def deleteds(true_or_false)
      select(:filename, :resolution, :realtime, :description).
      where(deleted: true_or_false).
      order(:realtime).
      all.
      reverse
    end
    def by_resolution_like(resolution)
      select(:filename, :resolution, :realtime, :description).
      where(deleted: false).
      filter(Sequel[:resolution].like(resolution)).
      all.
      reverse
    end
    def by_user(user)
      select(:filename, :resolution, :realtime, :description).
      where(user_id: user, deleted: false).
      all.
      reverse
    end
    def by_ids(id_list)
      select(:filename, :resolution, :realtime, :description).
      where(id: id_list, deleted: false).
      all.
      reverse
    end
    def order_by_date
      select(:filename,:resolution,:realtime,:resolution).
      reverse_order(:realtime).
      all
    end
    def by_date(initial_date, final_date)
      select(:filename, :resolution, :realtime, :description).
      where(realtime: initial_date..final_date, deleted: false).
      all.
      reverse
    end
    def by_date_and_user(initial_date, final_date, user)
      select(:filename, :resolution, :realtime, :description).
      where(realtime: initial_date..final_date, user_id: user, deleted: false).
      all
    end

  end
  many_to_many :users
  one_to_many :notifications
end
