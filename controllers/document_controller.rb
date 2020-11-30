require 'sinatra/base'
require './services/account_service'
require './services/document_service'
require './services/notification_service'
#require './exceptions/ValidationModelError.rb'

include FileUtils::Verbose

class Document_controller < Sinatra::Base

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

	get '/user_documents' do
		user_docs = Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id]))
		@not_checkeds = Document_service.documents_array(user_docs)
		user_docs = Document.by_ids(Notification.documents_id_checkeds_by_user(session[:user_id]))
		@checkeds = Document_service.documents_array(user_docs)
		erb :user_documents, :layout => :layout_loged_menu
	end

	post '/user_documents' do
		if params['path']
			doc_id = Document.first(:path => "/#{params['path']}")
			notification_checked = Notification.first(:user_id => session[:user_id], :document_id => doc_id.id)
			notification_checked.update(:checked => true)
		end
		@path = "/#{params['path']}"
		erb :view_doc, :layout => :layout_loged_menu
	end

	post '/check_documents' do
		if params['path']
			doc_id = Document.first(:path => "/#{params['path']}")
			notification_checked = Notification.first(:user_id => session[:user_id], :document_id => doc_id.id)
			notification_checked.update(:checked => true)
		end
		update_number_notifications_with_ws
		redirect '/user_documents'
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

	def search_record(resolution, ini_d, end_d, author)
		@initial_date = Document.first.realtime.strftime('%Y-%m-%d')
		@end_date = (Time.now + 86_400).strftime('%Y-%m-%d')
		ini_d == '' ? ini_d = @initial_date : ''
		end_d == '' ? end_d = @end_date : ''
		if resolution != ''
			@arr = Document_service.documents_array(Document.by_resolution_like(resolution))
		else
			search_record_by_date_and_au	get '/user_documents' do
		user_docs = Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id]))
		@not_checkeds = Document_service.documents_array(user_docs)
		user_docs = Document.by_ids(Notification.documents_id_checkeds_by_user(session[:user_id]))
		@checkeds = Document_service.documents_array(user_docs)
		erb :user_documents, :layout => :layout_loged_menu
	end

	post '/user_documents' do
		if params['path']
			doc_id = Document.first(:path => "/#{params['path']}")
			notification_checked = Notification.first(:user_id => session[:user_id], :document_id => doc_id.id)
			notification_checked.update(:checked => true)
		end
		@path = "/#{params['path']}"
		erb :view_doc, :layout => :layout_loged_menu
	end

	post '/check_documents' do
		if params['path']
			doc_id = Document.first(:path => "/#{params['path']}")
			notification_checked = Notification.first(:user_id => session[:user_id], :document_id => doc_id.id)
			notification_checked.update(:checked => true)
		end
		update_number_notifications_with_ws
		redirect '/user_documents'
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

	def search_record(resolution, ini_d, end_d, author)
		@initial_date = Document.first.realtime.strftime('%Y-%m-%d')
		@end_date = (Time.now + 86_400).strftime('%Y-%m-%d')
		ini_d == '' ? ini_d = @initial_date : ''
		end_d == '' ? end_d = @end_date : ''
		if resolution != ''
			@arr = Document_service.documents_array(Document.by_resolution_like(resolution))
		else
			search_record_by_date_and_author(ini_d, end_d, author)
		end
		@not_found_docs = 'No se encontraron actas relacionadas con su busqueda..' if @arr[0].nil?
	end

	def search_record_by_date_and_author(ini_d, end_d, author)
		ds = []
		author != '' and ds = User.find(:username => author) ? Document.by_date_and_user(ini_d, end_d, user_by_author.id) : Document.by_date(ini_d, end_d)
		@arr = Document_service.documents_array(ds)
	end

	post '/search_record' do
		search_record(params[:resolution], params[:initiate_date], params[:end_date], params[:author])
		erb :myrecords, :layout => :layout_loged_menu
	end

	post '/assign' do
		@arr = Document_service.documents_array Document.order_by_date
    @band = Account_service.message @current_user, params
		@usr = Account_service.set_menu session[:user_id], @current_user
		erb :assign, :layout => :layout_loged_menu
	end

	post '/load' do
		@time = Time.now
		tempfile = params[:pdf][:tempfile]
		@filename = "#{@time}#{params[:pdf][:filename]}"
		cp(tempfile.path, "public/temp/#{@filename}")
		erb :uploadrecord
	end

	post '/upload' do
		erb :uploadrecord
		request.body.rewind
		hash = Rack::Utils.parse_nested_query(request.body.read)
		params = JSON.parse hash.to_json
		@tagged = params['tagg']
		cp("public/temp/#{params['path']}", "public/file/#{params['path']}")
		document = Document.new(
			:resolution => params ['resolution'],
			:path => "/file/#{params['path']}",
			:filename => params['filena'],
			:description => params['description'],
			:realtime => params['realtime'],
			:user_id => @current_user.id
		)
		if document.save
			@record = document
			erb :tagg
		else
			[500, {}, 'Internal server Error']
		end
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
thor(ini_d, end_d, author)
		end
		@not_found_docs = 'No se encontraron actas relacionadas con su busqueda..' if @arr[0].nil?
	end

	def search_record_by_date_and_author(ini_d, end_d, author)
		ds = []
		author != '' and ds = User.find(:username => author) ? Document.by_date_and_user(ini_d, end_d, user_by_author.id) : Document.by_date(ini_d, end_d)
		@arr = Document_service.documents_array(ds)
	end

	post '/search_record' do
		search_record(params[:resolution], params[:initiate_date], params[:end_date], params[:author])
		erb :myrecords, :layout => :layout_loged_menu
	end

	post '/assign' do
		@arr = Document_service.documents_array Document.order_by_date
    @band = Account_service.message @current_user, params
		@usr = Account_service.set_menu session[:user_id], @current_user
		erb :assign, :layout => :layout_loged_menu
	end

	post '/load' do
		@time = Time.now
		tempfile = params[:pdf][:tempfile]
		@filename = "#{@time}#{params[:pdf][:filename]}"
		cp(tempfile.path, "public/temp/#{@filename}")
		erb :uploadrecord
	end

	post '/upload' do
		erb :uploadrecord
		request.body.rewind
		hash = Rack::Utils.parse_nested_query(request.body.read)
		params = JSON.parse hash.to_json
		@tagged = params['tagg']
		cp("public/temp/#{params['path']}", "public/file/#{params['path']}")
		document = Document.new(
			:resolution => params ['resolution'],
			:path => "/file/#{params['path']}",
			:filename => params['filena'],
			:description => params['description'],
			:realtime => params['realtime'],
			:user_id => @current_user.id
		)
		if document.save
			@record = document
			erb :tagg
		else
			[500, {}, 'Internal server Error']
		end
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
