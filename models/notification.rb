class Notification < Sequel::Model(:documents_users)
  dataset_module do

    def documents_id_checkeds_by_user(user_id)
      select(:document_id).
      where(user_id: user_id, checked: true)
    end

    def documents_id_uncheckeds_by_user(user_id)
      select(:document_id).
      where(user_id: user_id, checked: false)
    end
    def number_of_uncheckeds_for_user(user)
      where(user_id: user, checked: false).
      count
    end
  end
  many_to_one :document
  many_to_one :user
end
