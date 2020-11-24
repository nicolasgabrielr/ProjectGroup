#require './exceptions/ValidationModelError.rb'
require './models/user.rb'

class General_service

	def self.documents_array(documents)
    documents.map do |x|
      file = { :filename => x.filename,
               :resolution => x.resolution,
               :description => x.description,
               :date => x.realtime.strftime('%d/%m/%y') }
    end
	end

	def self.current_user(session)
		User.find(:id => session[:user_id])
  end

	def self.number_of_uncheckeds(session)
	  Notification.number_of_uncheckeds_for_user(session[:user_id])
  end
end
