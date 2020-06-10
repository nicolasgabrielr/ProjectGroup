require 'json'
require './models/init.rb'
require 'sinatra-websocket'

include FileUtils::Verbose

class App < Sinatra::Base




  configure do
    enable :logging
    enable :sessions
    set :session_fail, '/'
    set :session_secret, "otro secret pero dificil y abstracto"
    set :sessions, true

    set :server, 'thin'
    set :sockets, []
  end


  get '/' do
    if !request.websocket?
      get_public_documents
      erb :index, :layout => :layout_public_records
    else
      request.websocket do |ws|
        user = session[:user_id]
        @connection = {user: user, socket: ws}
        ws.onopen do
          settings.sockets << @connection
        end
      end
    end
  end


  before do
    request.path_info
    if user_not_logged_in? && restricted_path_for_guest?
      redirect '/index'
    elsif session[:user_id]
      @current_user = User.find(id: session[:user_id])
      alert_notification(session[:user_id])
      set_menu

      if not_eauthorized_category_for_admin? && superAdmin_path?
        redirect '/index'
      elsif not_eauthorized_category_for_user? && admin_path?
        redirect '/index'
      end
    end
  end

  def user_not_logged_in?
    !session[:user_id]
  end

  def superAdmin_path?
    request.path_info == '/assign'
  end

  def admin_path?
    request.path_info == '/tagg' || request.path_info == '/upload'|| request.path_info == '/load'|| request.path_info == '/uploadrecord'
  end

  def restricted_path_for_guest?
    request.path_info != '/index' && request.path_info != '/sign_in' && request.path_info != '/' && request.path_info != '/about' && request.path_info != '/newUser' && request.path_info != '/tablas'
  end

  def not_eauthorized_category_for_admin?
    @current_user.category != "superAdmin"
  end

  def not_eauthorized_category_for_user?
    @current_user.category != "superAdmin" && @current_user.category != "admin"
  end


  def set_menu
    if user_not_logged_in?
      redirect '/index'
    end
    case @current_user.category
      when "superAdmin" then
        @admin = "visible"
        @superAdmin = "visible"
      when "admin" then
        @admin = "visible"
        @superAdmin = "hidden"
      else
        @admin = "hidden"
        @superAdmin = "hidden"
      end
        @usuario = session[:user_name]
  end

  def get_public_documents
    public_docs = Document.deleteds(false)
     @arr = public_docs.map{|x| x.filename}
  end

  def checkpass(key)
    @current_user.password == key
  end

  get '/user_documents' do
    user_docs = Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id]))
    @not_checkeds = user_docs.map{|x| x.filename}
    user_docs = Document.by_ids(Notification.documents_id_checkeds_by_user(session[:user_id]))
    @checkeds = user_docs.map{|x| x.filename}
    erb:user_documents , :layout => :layout_loged_menu
  end

  post '/user_documents' do
    if params["path"]
      doc_id = Document.first(path: "/#{params["path"]}")
      notification_checked = Notification.first(user_id: session[:user_id], document_id: doc_id.id)
      notification_checked.update(checked: true)
    end
    @path =  "/#{params["path"]}"
    erb:view_doc , :layout => :layout_loged_menu
  end

  post '/check_documents' do
    if params["path"]
      doc_id = Document.first(path: "/#{params["path"]}")
      notification_checked = Notification.first(user_id: session[:user_id], document_id: doc_id.id)
      notification_checked.update(checked: true)
    end
    redirect '/user_documents'
  end

  get '/myrecords' do
    ds = Document.by_user(session[:user_id])
    @arr = ds.map{|x| x.filename}
    get_initial_and_final_date
    erb:myrecords , :layout => :layout_loged_menu
  end

  post '/myrecords' do
    if params[:delete]
      delete_document(params["elem"]) #elem is name of document
      redirect "/myrecords"
    else
      "No se pudo eliminar el documento"
    end
    if params[:taggear]
      @record = Document.find(filename: params["elem"])
      @dni_docc = User.select(:dni).where(id: Notification.select(:user_id).where(document_id: @record.id))
      erb:tagg
    end
  end

  post '/search_record' do
    if params[:resolution] != ""
      ds = Document.by_resolution(params[:resolution])
      @arr = ds.map{|x| x.filename}
      if @arr[0] == nil
        @not_found_docs = "No se encontraron actas con dicha resolución.."
      end
    elsif params[:initiate_date] || params[:end_date]
      ds = []
      user_by_author = User.find(username: params[:author])
      if user_by_author
        ds = Document.by_date_and_user(params[:initiate_date], params[:end_date], user_by_author.id)
      elsif (params[:author] == "")
        ds = Document.by_date(params[:initiate_date], params[:end_date])
      end
      @arr = ds.map{|x| x.filename}
      if @arr[0] == nil
        @not_found_docs = "No se encontraron actas relacionadas con su busqueda.."
      end
    end
    get_initial_and_final_date
    erb:myrecords , :layout => :layout_loged_menu
  end

  post '/tagg' do
    @tagged = params["tagg"]
    document = Document.find(id: params["doc"])
    if @tagged != nil
      @tagged.map{|u| tagg_user(u,document)} #tagged involved users
    end
    document.update(description: params["description"], resolution: params["resolution"])
    settings.sockets.each{|s| alert_notification(s[:user])
      s[:socket].send(@alert.to_s)
     }
    redirect "/myrecords"
  end

  def alert_notification(user)
    @alert =   Notification.number_of_uncheckeds_for_user(user)
  end

  def tagg_user(dni,document)
    user_tagg = User.find(dni: dni)
    if user_tagg != nil
      document.add_user(user_tagg)
    else
      request.body.rewind
      hash = Rack::Utils.parse_nested_query(request.body.read)
      params = JSON.parse hash.to_json
      string_dni = dni.to_s
      not_user = User.new(surname: string_dni , category: "not_user",  name: string_dni, username: string_dni  , dni: dni, password: "not_user#{string_dni}" , email: "#{string_dni}@email.com")
      if not_user.save
        document.add_user(not_user)
      else
        [500, {}, "Internal server Error"]
      end
    end
  end

  get '/loged' do
    get_public_documents
    erb:loged , :layout => :layout_loged_menu
  end

  post '/sign_in' do #inicio de sesion
    get_public_documents
    usuario = User.find(email: params["email"])
    if usuario != nil && (usuario.password == params["password"])
      session[:user_name] = usuario.name
      session[:user_id] = usuario.id
      @current_user = User.find(id: session[:user_id])
      set_menu

      alert_notification(session[:user_id])
      erb:loged , :layout => :layout_loged_menu
    elsif usuario == nil
      @log_err = "El usuario ingresado no existe"
      erb:index , :layout => :layout_public_records
    else
      @log_err = "La contraseña ingresada es incorrecta"
      erb:index , :layout => :layout_public_records
    end
  end

  post '/assign' do #asignacion de admin o super admin
    @band
    #filtra la tabla
    orderbydate=Document.select(:filename,:resolution,:realtime).reverse_order(:realtime).all
    @arr= orderbydate.map{|x| x.filename}
      if checkpass(params["passwordActual"])
        usuario = User.find(email: params["emailnewAdmin"])
        if params[:dUser] && usuario != nil
          usuario.destroy
          @band = "¡El usuario ha sido eliminado con Exito!"
        else
          @band = "¡El usuario no existe o no se pudo eliminar!"
        end
        if params[:admin]
          usuario.update(category:"admin")
          @band = "¡El Administrador ha sido cargado con exito!"
        elsif params[:sAdmin]
          usuario.update(category:"superAdmin")
          @band = "¡El Administrador ha sido cargado con exito!"
        end
      else
        @band = "El password es incorrecto o el usuario no existe"
      end

    set_menu
    erb:assign , :layout => :layout_loged_menu
  end

  get '/assign' do
    erb :assign , :layout => :layout_loged_menu
  end

  get '/sign_in' do  #sesion iniciada get
    get_public_documents
    if session[:user_id]

      set_menu
      erb:loged , :layout => :layout_loged_menu
    else
      erb:index , :layout => :layout_public_records
    end
  end

  get '/sign_out' do  #cierre de sesion
    session.clear
    erb:index , :layout => :layout_public_records
  end

  get "/notificationlist" do
    erb:notificationlist
  end

  get "/index" do
    get_public_documents
    session.clear
    erb :index , :layout => :layout_public_records
  end

  get "/about" do
    erb:about
  end

  get '/newUser' do
    erb:newUser
  end

  get '/mydata' do
    @isAdmin = @current_user.category
    @username = @current_user.name
    @foto = @current_user.imgpath
    @name = @current_user.name
    @surname = @current_user.surname
    @dni = @current_user.dni
    erb:mydata , :layout => :layout_loged_menu
  end

  get '/modifyemail' do
    erb:modifyemail , :layout => :layout_loged_menu
  end

  post '/modifyemail' do
    if checkpass(params["passwordActual"])
      @current_user.update(email: params["emailNew1"])
      @band = "¡El email ha sido Actualizado con exito!"
    else
      @band = "La contraseña o el email son Incorrectos!"
    end

    set_menu
    erb:modifyemail , :layout => :layout_loged_menu
  end

  get '/modifypassword' do
    erb:modifypassword , :layout => :layout_loged_menu
  end

  post '/modifypassword' do
    if checkpass(params["passwordActual"])
      @current_user.update(password: params["passwordNew1"])
      @band = "¡El password ha sido Actualizado con exito!"
    else
      @band = "La contraseña ingresada es incorrecta"
    end
    erb:modifypassword , :layout => :layout_loged_menu
  end

  get '/modifyphoto' do
    erb:modifyphoto
  end

  get '/uploadrecord' do  #carga de ducumentos
      erb:uploadrecord
  end

  post '/newUser' do   #cargar un nuevo usuario
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    pre_load_user = User.find(dni: params["dni"])
      if pre_load_user
        pre_load_user.update(surname: params["surname"], category: "user",  name: params["name"], username: params["username"], dni: params["dni"], password: params["key"], email: params["email"] )
        redirect "/"
      else
        user = User.new(surname: params["surname"], category: "user",  name: params["name"], username: params["username"], dni: params["dni"], password: params["key"], email: params["email"] )
        if user.save
          redirect "/"
        else
          [500, {}, "Internal server Error"]
        end
      end
  end

  get '/uploadImg' do  #carga de fotos
    erb:modifyphoto
  end

  post '/uploadImg' do     #cargar imagenes a la base de datos
    if @current_user.imgpath != nil && File.exist?("public#{@current_user.imgpath}")
      File.delete("public#{@current_user.imgpath}")
    end
    tempfile = params[:myImg][:tempfile]
    @filename = params[:myImg][:filename]
    cp(tempfile.path, "public/usr/#{@filename}")
    @current_user.update(imgpath: "/usr/#{@filename}")
    redirect "/mydata"
  end

  post '/load' do   #vista previa del documento para extraer datos y tags
    @time = Time.now
    tempfile = params[:pdf][:tempfile]
    @filename = "#{@time}#{params[:pdf][:filename]}"
    cp(tempfile.path, "public/temp/#{@filename}")
    erb :uploadrecord
  end

  post '/upload' do     #upload documents and taggs users
    erb :uploadrecord
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    @tagged = params["tagg"]
    cp("public/temp/#{params["path"]}","public/file/#{params["path"]}")
    document = Document.new(resolution: params ["resolution"],path: "/file/#{params["path"]}",filename: params["filena"], description: params["description"], realtime: params["realtime"], user_id: @current_user.id)
    if document.save
      @record = document
      erb:tagg
    else
      [500, {}, "Internal server Error"]
    end
  end

  def delete_document(name)
    if File.exist?("public/file/#{name}")
      deleting_doc = Document.find(filename: name)
      ds = Notification.where(document_id: deleting_doc.id).all
      ds.each { |n| n.update(checked: true)}
      deleting_doc.update(deleted: true) #delete from db
      #File.delete("public/file/#{name}") #delete from system
    else
      "cannot delete this Doc"
    end
  end



  def get_initial_and_final_date
    @initial_date = Document.first.realtime.strftime("%Y-%m-%d")
    @end_date = ((Time.now) + 86400).strftime("%Y-%m-%d")
  end


## Pruebas para ver las tablas

  get "/prueba" do


      Notification.number_of_uncheckeds_for_user(session[:user_id]).to_s
        #Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id])).to_s
    #pp=Document.where(users: User[28]).all
    #pp.last.path
    #User[28].documents
    #User.each { |u| @out+=u.email+"<br/>" }
    #a.chars.last(5).join
    #User[20].delete
    #Document[47].delete
    #Document.select(:filename).delete
    #PARA MODIFICAR UN REGISTRO
    #user = User.last
    #user.update(category: superAdmin)
    #PARA MOSTRAR UN REGISTRO
    #usuario = User.first(id:2)
    #usuario.update(category:"admin")
    #usuario = User.first(id: session[:user_id])
    #u = usuario.name
    #Notification.documents_id_uncheckeds_by_user(session[:user_id]).to_s
    #User.all.to_s
  end

  get '/rename' do
    docs = Document.all
    docs.each do |i|
      i.update(resolution: (i.id + 100000).to_s)
      i.update(description: "UNRC acta res/#{(i.id + 100000).to_s}")
    end
     "rename ok"
  end

  get '/tablas' do
    @out = ""
    User.each { |u| @out+= u.email + "--" + u.category.to_s +  "<br/>" }
    @out +="<br/>"
    Document.each { |d| @out+=d.path+"<br/>" }
    @out +="<br/>"+ "listado de documentos ----> usuarios" + "<br/>"
    Document.each { |d| @out+= d.path + " ------relacionado con----- " + d.users.to_s + "<br/>" }
    @out +="<br/>"+ "listado de usuarios ----> documentos" + "<br/>"
    User.each { |u| @out+= u.email + " -----relacionado con----- " + u.documents.to_s + "<br/>" }
    @out +="<br/>"
    end
end
