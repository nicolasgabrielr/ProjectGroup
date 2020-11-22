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

end