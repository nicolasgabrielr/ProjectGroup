require './models/user.rb'

class Notification_service

	def self.number_of_uncheckeds(session)
	  Notification.number_of_uncheckeds_for_user(session[:user_id])
  end

end
