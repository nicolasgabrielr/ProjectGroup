require 'sinatra/base'
require './services/account_service'
require './services/document_service'
#require './exceptions/ValidationModelError.rb'

include FileUtils::Verbose

class Base_controller < Sinatra::Base

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
		  @alert = Notification.number_of_uncheckeds_for_user(session[:user_id])
		end
		@arr = Document_service.documents_array(Document.deleteds(false))
  end

	get '/index' do
		@log_err
		@arr = Document_service.documents_array(Document.deleteds(false))
		session.clear
		erb :index, :layout => :layout_public_records
	end

	post '/index' do
		if params[:dni] != '' && !params[:dni].nil?
			user = User.find(:dni => params[:dni])
			if user
				public_docs = user.documents_dataset.where(:deleted => false).reverse_order { documents[:realtime] }
				@arr = Document_service.documents_array(public_docs)
			else
				@arr = Document_service.documents_array(Document.deleteds(false))
			end
		elsif (params[:resolution] != '' && !params[:resolution].nil?) ||
					(params[:initiate_date] != '' && !params[:initiate_date].nil?) ||
					(params[:end_date] != '' && !params[:end_date].nil?)
			search_record(params[:resolution], params[:initiate_date], params[:end_date], '')
		else
			@arr = Document_service.documents_array(Document.deleteds(false))
		end
		erb :index, :layout => :layout_public_records
	end

	get '/about' do
		erb :about
	end


end
