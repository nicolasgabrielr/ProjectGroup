require 'json'
require './models/init.rb'
require 'sinatra-websocket'
require './controllers/account_controller.rb'
require './services/account_service'
require './services/general_service'

include FileUtils::Verbose

class App < Sinatra::Base
  configure do
    enable :logging
    enable :sessions
    set :session_fail, '/'
    set :session_secret, 'otro secret pero dificil y abstracto'
    set :sessions, true
    set :server, 'thin'
    set :sockets, []
  end

  use Account_controller

  def init_folders
    folders_list = ['public/usr/', 'public/temp/', 'public/file/']
    folders_list.each do |f|
      Dir.mkdir(f) unless Dir.exist?(f)
    end
  end

  get '/' do
    init_folders
    if !request.websocket?
      @arr = General_service.documents_array(Document.deleteds(false))
      erb :index, :layout => :layout_public_records
    else
      request.websocket do |ws|
        user = session[:user_id]
        logger.info(user)
        @connection = { :user => user, :socket => ws }
        ws.onopen do
          settings.sockets << @connection
        end
      end
    end
  end

  def update_number_notifications_with_ws
    settings.sockets.each do |s|
      alert_notification(s[:user])
      s[:socket].send(@alert.to_s)
    end
  end

  post '/tagg' do
    @tagged = params['tagg']
    document = Document.find(:id => params['doc'])
    @tagged&.map { |u| tagg_user(u, document) }
    document.update(:description => params['description'], :resolution => params['resolution'])
    update_number_notifications_with_ws
    redirect '/myrecords'
  end

  superAdmin_Pages = ['/assign']
  admin_Pages = ['/tagg', '/upload', '/load', '/uploadrecord']
  public_Pages = ['/index', '/sign_in', '/', '/about', '/newUser', '/tablas']

  before do
    request.path_info
    if user_not_logged_in? && !public_Pages.include?(request.path_info)
      redirect '/index'
    elsif session[:user_id]
      @current_user = User.find(:id => session[:user_id])
      alert_notification(session[:user_id])
      Account_service.set_menu(session[:user_id])
      if not_authorized_category_for_admin? && superAdmin_Pages.include?(request.path_info)
        redirect '/index'
      elsif not_authorized_category_for_user? && admin_Pages.include?(request.path_info)
        redirect '/index'
      end
    end
  end

  def user_not_logged_in?
    !session[:user_id]
  end

  def not_authorized_category_for_admin?
    @current_user.category != 'superAdmin'
  end

  def not_authorized_category_for_user?
    @current_user.category != 'superAdmin' && @current_user.category != 'admin'
  end

  def checkpass(key)
    @current_user.password == key
  end

  get '/user_documents' do
    user_docs = Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id]))
    @not_checkeds = General_service.documents_array(user_docs)
    user_docs = Document.by_ids(Notification.documents_id_checkeds_by_user(session[:user_id]))
    @checkeds = General_service.documents_array(user_docs)
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

  get '/myrecords' do
    ds = Document.by_user(session[:user_id])
    @arr = @arr = General_service.documents_array(ds)
    get_initial_and_final_date
    erb :myrecords, :layout => :layout_loged_menu
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

  def search_record(resolution, ini_d, end_d, author)
    get_initial_and_final_date
    ini_d == '' ? ini_d = @initial_date : ''
    end_d == '' ? end_d = @end_date : ''
    if resolution != ''
      @arr = General_service.documents_array(Document.by_resolution_like(resolution))
    else
      search_record_by_date_and_author(ini_d, end_d, author)
    end
    @not_found_docs = 'No se encontraron actas relacionadas con su busqueda..' if @arr[0].nil?
  end

  def search_record_by_date_and_author(ini_d, end_d, author)
    ds = []
    author != '' and ds = User.find(:username => author) ? Document.by_date_and_user(ini_d, end_d, user_by_author.id) : Document.by_date(ini_d, end_d)
    @arr = General_service.documents_array(ds)
  end

  post '/search_record' do
    search_record(params[:resolution], params[:initiate_date], params[:end_date], params[:author])
    erb :myrecords, :layout => :layout_loged_menu
  end

  def alert_notification(user)
    @alert = Notification.number_of_uncheckeds_for_user(user)
  end

  def tagg_user(dni, document)
    if User.find(:dni => dni)
      if User.find(:dni => dni) && !Notification.find(:user_id => User.find(:dni => dni).id, :document_id => document.id)
        document.add_user(User.find(:dni => dni))
      end
    else
      not_user_tagg = add_generic_user(dni.to_s, dni)
      if not_user_tagg.save
        document.add_user(not_user_tagg)
      else
        [500, {}, 'Internal server Error']
      end
    end
  end

  def add_generic_user(string_dni, dni)
    User.new(
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

  get '/loged' do
    @arr = General_service.documents_array(Document.deleteds(false))
    erb :loged, :layout => :layout_loged_menu
  end

  post '/loged' do
    if params[:dni] != '' && !params[:dni].nil?
      user = User.find(:dni => params[:dni])
      if user
        public_docs = user.documents(:deleted => false)
        @arr = General_service.documents_array(public_docs)
      else
        @arr = General_service.documents_array(Document.deleteds(false))
      end
    elsif params[:resolution] != '' || params[:initiate_date] != '' || params[:end_date] != ''
      search_record(params[:resolution], params[:initiate_date], params[:end_date], '')
    else
      @arr = General_service.documents_array(Document.deleteds(false))
    end
    erb :loged, :layout => :layout_loged_menu
  end

  post '/assign' do
    docs = Document.order_by_date
    @arr = General_service.documents_array(docs)
    if checkpass(params['passwordActual'])
      usuario = User.find(:email => params['emailnewAdmin'])
      if params[:dUser] && !usuario.nil?
        usuario.destroy
        @band = '¡El usuario ha sido eliminado con Exito!'
      else
        @band = '¡El usuario no existe o no se pudo eliminar!'
      end
      if params[:admin]
        usuario.update(:category => 'admin')
        @band = '¡El Administrador ha sido cargado con exito!'
      elsif params[:sAdmin]
        usuario.update(:category => 'superAdmin')
        @band = '¡El Administrador ha sido cargado con exito!'
      end
    else
      @band = 'El password es incorrecto o el usuario no existe'
    end

    Account_service.set_menu(session[:user_id])
    erb :assign, :layout => :layout_loged_menu
  end

  get '/assign' do
    erb :assign, :layout => :layout_loged_menu
  end

  get '/sign_in' do
    @arr = General_service.documents_array(Document.deleteds(false))
    if session[:user_id]

      Account_service.set_menu(session[:user_id])
      erb :loged, :layout => :layout_loged_menu
    else
      erb :index, :layout => :layout_public_records
    end
  end

  get '/sign_out' do
    session.clear
    erb :index, :layout => :layout_public_records
  end

  get '/notificationlist' do
    erb :notificationlist
  end

  get '/index' do
    @log_err
    @arr = General_service.documents_array(Document.deleteds(false))
    session.clear
    erb :index, :layout => :layout_public_records
  end

  post '/index' do
    if params[:dni] != '' && !params[:dni].nil?
      user = User.find(:dni => params[:dni])
      if user
        public_docs = user.documents_dataset.where(:deleted => false).reverse_order { documents[:realtime] }
        @arr = General_service.documents_array(public_docs)
      else
        @arr = General_service.documents_array(Document.deleteds(false))
      end
    elsif (params[:resolution] != '' && !params[:resolution].nil?) ||
          (params[:initiate_date] != '' && !params[:initiate_date].nil?) ||
          (params[:end_date] != '' && !params[:end_date].nil?)
      search_record(params[:resolution], params[:initiate_date], params[:end_date], '')
    else
      @arr = General_service.documents_array(Document.deleteds(false))
    end
    erb :index, :layout => :layout_public_records
  end

  get '/about' do
    erb :about
  end

  get '/mydata' do
    @isAdmin = @current_user.category
    @username = @current_user.name
    @foto = @current_user.imgpath
    @name = @current_user.name
    @surname = @current_user.surname
    @dni = @current_user.dni
    erb :mydata, :layout => :layout_loged_menu
  end

  get '/modifyData' do
    erb :modifyData, :layout => :layout_loged_menu
  end

  post '/modifyData' do
    @current_user.update(:name => params['newName'])
    @current_user.update(:surname => params['newSurname'])
    @band = '¡Datos actualizados corretamente!'
    Account_service.set_menu(session[:user_id])
    erb :modifyData, :layout => :layout_loged_menu
  end
  get '/modifyemail' do
    erb :modifyemail, :layout => :layout_loged_menu
  end

  post '/modifyemail' do
    if checkpass(params['passwordActual'])
      @current_user.update(:email => params['emailNew1'])
      @band = '¡El email ha sido Actualizado con exito!'
    else
      @band = 'La contraseña o el email son Incorrectos!'
    end
    Account_service.set_menu(session[:user_id])
    erb :modifyemail, :layout => :layout_loged_menu
  end

  get '/modifypassword' do
    erb :modifypassword, :layout => :layout_loged_menu
  end

  post '/modifypassword' do
    if checkpass(params['passwordActual'])
      @current_user.update(:password => params['passwordNew1'])
      @band = '¡El password ha sido Actualizado con exito!'
    else
      @band = 'La contraseña ingresada es incorrecta'
    end
    erb :modifypassword, :layout => :layout_loged_menu
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

  def get_initial_and_final_date
    @initial_date = Document.first.realtime.strftime('%Y-%m-%d')
    @end_date = (Time.now + 86_400).strftime('%Y-%m-%d')
  end

end