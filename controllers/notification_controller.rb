require 'sinatra/base'
require './services/account_service'
require './services/document_service'
require './services/notification_service'

include FileUtils::Verbose

class Notification_controller < Sinatra::Base

	configure do
		enable :logging
		enable :sessions
		set :session_fail, '/'
		set :session_secret, 'otro secret pero dificil y abstracto'
		set :sessions, true
		set :views, settings.root + '/../views'
		set :server, 'thin'
		set :sockets, []
	end

  public_Pages = ['/index', '/sign_in', '/', '/about', '/newUser']

	before do
		if session[:user_id]
		  @current_user = Account_service.current_user session
			@usr = Account_service.set_menu session[:user_id], @current_user
		  @alert = Notification_service.number_of_uncheckeds session
		end
		@arr = Document_service.documents_array(Document.deleteds(false))
  end

	get '/notificationlist' do
		erb :notificationlist
	end

	post '/tagg' do
		@tagged = params['tagg']
		document = Document.find(:id => params['doc'])
		@tagged&.map { |u| Document_service.tagg_user(u, document) }
		document.update(:description => params['description'], :resolution => params['resolution'])
		update_number_notifications_with_ws
		redirect '/myrecords'
	end

	def update_number_notifications_with_ws
		settings.sockets = $ws
    settings.sockets.each do |s|
    	@alert = Notification_service.number_of_uncheckeds session
      s[:socket].send(@alert.to_s)
    end
  end

end
