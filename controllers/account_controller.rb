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

  public_Pages = ['/index', '/sign_in', '/', '/about', '/newUser']

	before do
		if session[:user_id]
		  @current_user = General_service.current_user session
			@usr = Account_service.set_menu session[:user_id], @current_user
		  @alert = Notification.number_of_uncheckeds_for_user(session[:user_id])
		end
		@arr = General_service.documents_array(Document.deleteds(false))
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
		else
			@arr = General_service.documents_array Document.deleteds(false)
			return erb :index, :layout => :layout_public_records
	end

	post '/sign_in' do
		Account_service.sign_in params, session
		rescue ArgumentError => e
			return erb :index, :locals => {:log_err => e.message}, :layout => :layout_public_records
		else
			@current_user = General_service.current_user session
	    @usr = Account_service.set_menu session[:user_id], @current_user
			@alert = General_service.number_of_uncheckeds session
			return erb :loged, :layout => :layout_loged_menu
	end

	get '/loged' do
    return erb :loged, :layout => :layout_loged_menu
  end

  post '/loged' do
    Account_service.loged params
		@usr = Account_service.set_menu session[:user_id], @current_user
		return erb :loged, :layout => :layout_loged_menu
  end

	get '/sign_in' do
		rescue ArgumentError => e
		  return erb :index, :locals => {:log_err => e.message}, :layout => :layout_public_records
		else
			return erb :loged, :layout => :layout_loged_menu
	end

	get '/sign_out' do
		session.clear
		erb :index, :layout => :layout_public_records
	end

	get '/mydata' do
    erb :mydata, :layout => :layout_loged_menu
  end

  get '/modifyData' do
    erb :modifyData, :layout => :layout_loged_menu
  end

	get '/modifyemail' do
		erb :modifyemail, :layout => :layout_loged_menu
	end

	get '/modifyphoto' do
		erb :modifyphoto
	end

	get '/uploadrecord' do
		erb :uploadrecord
	end

	get '/uploadImg' do
		erb :modifyphoto
	end

	get '/modifypassword' do
		erb :modifypassword, :layout => :layout_loged_menu
	end

  post '/modifyData' do
		Account_service.modify_data @current_user, params, @band
    @usr = Account_service.set_menu session[:user_id], @current_user
    erb :modifyData, :layout => :layout_loged_menu
  end

  post '/modifyemail' do
    Account_service.modify_email @current_user, params, @band
    @usr = Account_service.set_menu session[:user_id], @current_user
    erb :modifyemail, :layout => :layout_loged_menu
  end

  post '/modifypassword' do
		Account_service.modify_password @current_user, params, @band
    erb :modifypassword, :layout => :layout_loged_menu
  end

  post '/uploadImg' do
    if !@current_user.imgpath.nil? && File.exist?("public#{@current_user.imgpath}")
      File.delete("public#{@current_user.imgpath}")
    end
    tempfile = params[:myImg][:tempfile]
    @filename = params[:myImg][:filename]
    cp(tempfile.path, "public/usr/#{@filename}")
    @current_user.update(:imgpath => "/usr/#{@filename}")
    redirect '/mydata'
  end

end
