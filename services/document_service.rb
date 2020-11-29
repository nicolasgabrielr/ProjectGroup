#require './exceptions/ValidationModelError.rb'
require './models/user.rb'

class Document_service

	def self.tagg_user(dni, document)
		if User.find(:dni => dni)
			if User.find(:dni => dni) && !Notification.find(:user_id => User.find(:dni => dni).id, :document_id => document.id)
				document.add_user(User.find(:dni => dni))
			end
		else
			add_generic_user(dni.to_s, dni)
		end
	end

	def self.documents_array(documents)
		documents.map do |x|
			file = { :filename => x.filename,
							 :resolution => x.resolution,
							 :description => x.description,
							 :date => x.realtime.strftime('%d/%m/%y') }
		end
	end

	def self.number_of_uncheckeds(session)
	  Notification.number_of_uncheckeds_for_user(session[:user_id])
  end

	def self.add_generic_user(string_dni, dni)
		not_user_tagg = User.new(
			:surname => string_dni,
			:category => 'not_user',
			:name => string_dni,
			:username => string_dni,
			:dni => dni,
			:password => "not_user#{string_dni}",
			:email => "#{string_dni}@email.com"
		)
		if not_user_tagg.save
			document.add_user(not_user_tagg)
		else
			[500, {}, 'Internal server Error']
		end
	end

end
