require 'sinatra/base'
require './services/account_service'
#require './exceptions/ValidationModelError.rb'

class Account_controller < Sinatra::Base

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

	get '/newUser' do
		erb :newUser
	end

	post '/newUser' do
		request.body.rewind
		hash = Rack::Utils.parse_nested_query(request.body.read)
		params = JSON.parse hash.to_json
		Account_service.newUser params
		rescue ArgumentError => e
			return erb :newUser, :locals => {:log_err => e.message}
	end

	post '/sign_in' do
		@arr = General_service.documents_array Document.deleteds(false)
		Account_service.sign_in params, session
		rescue ArgumentError => e
			return erb :index, :locals => {:log_err => e.message}, :layout => :layout_public_records
		else
			@current_user = User.find(:id => session[:user_id])
			Account_service.set_menu(session[:user_id])
			@alert = Notification.number_of_uncheckeds_for_user(session[:user_id])
			return erb :loged, :layout => :layout_loged_menu
	end

end

