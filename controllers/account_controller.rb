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
    begin
    	Account_service.newUser params
	    erb :newUser
	  end
  end

end

