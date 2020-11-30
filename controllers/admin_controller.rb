require 'sinatra/base'
require './services/account_service'
require './services/document_service'
require './services/notification_service'
#require './exceptions/ValidationModelError.rb'

include FileUtils::Verbose

class Admin_controller < Sinatra::Base

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

	get '/assign' do
		erb :assign, :layout => :layout_loged_menu
	end

	post '/myrecords' do
		if params[:delete]
			delete_document(params['elem'])
			update_number_notifications_with_ws
			redirect '/myrecords'
		else
			'No se pudo eliminar el documento'
		end
		if params[:taggear]
			@record = Document.find(:filename => params['elem'])
			@dni_docc = User.select(:dni).where(:id => Notification.select(:user_id).where(:document_id => @record.id))
			erb :tagg
		end
	end

	get '/myrecords' do
		@arr = Document_service.documents_array(Document.by_user(session[:user_id]))
		@initial_date = Document.first.realtime.strftime('%Y-%m-%d')
		@end_date = (Time.now + 86_400).strftime('%Y-%m-%d')
		erb :myrecords, :layout => :layout_loged_menu
	end

	post '/assign' do
		@arr = Document_service.documents_array Document.order_by_date
    @band = Account_service.message @current_user, params
		@usr = Account_service.set_menu session[:user_id], @current_user
		erb :assign, :layout => :layout_loged_menu
	end


	def delete_document(name)
		if File.exist?("public/file/#{name}")
			deleting_doc = Document.find(:filename => name)
			ds = Notification.where(:document_id => deleting_doc.id).all
			ds.each { |n| n.update(:checked => true) }
			deleting_doc.update(:deleted => true)
		else
			'cannot delete this Doc'
		end
	end

	def update_number_notifications_with_ws
		settings.sockets = $ws
    settings.sockets.each do |s|
    	@alert = Notification.number_of_uncheckeds_for_user(s[:user])
      s[:socket].send(@alert.to_s)
    end
  end

end
