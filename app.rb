require 'json'
require './models/init.rb'
include FileUtils::Verbose

class App < Sinatra::Base

  configure do
    enable :logging
    enable :sessions
    set :session_fail, '/'
    set :session_secret, "otro secret pero dificil y abstracto"
    set :sessions, true
  end

  before do
    request.path_info
    if user_not_logged_in? && restricted_path_for_guest?
      redirect '/index'
    elsif session[:user_id]
      @current_user = User.find(id: session[:user_id])
      alert_notification
      set_user
      if not_eauthorized_category_for_admin? && superAdmin_path?
        redirect '/index'
      elsif not_eauthorized_category_for_user? && admin_path?
        redirect '/index'
      end
    end
  end

  def alert_notification
    notification_unchecked = Notification.where(user_id: session[:user_id], checked: false).all
    if notification_unchecked
      n=0
      notification_unchecked.each{|d| n=n+1}
      @alert = n
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
    request.path_info != '/index' && request.path_info != '/sign_in' && request.path_info != '/' && request.path_info != '/about' && request.path_info != '/newUser' && request.path_info != '/prueba'
  end

  def not_eauthorized_category_for_admin?
    @current_user.category != "superAdmin"
  end

  def not_eauthorized_category_for_user?
    @current_user.category != "superAdmin" && @current_user.category != "admin"
  end

  def set_user
    case @current_user.category
      when "superAdmin" then
        @admin = "submit"
        @superAdmin = "submit"
      when "admin" then
        @admin = "submit"
        @superAdmin = "hidden"
      else
        @admin = "hidden"
        @superAdmin = "hidden"
      end
        @usuario = session[:user_name]
  end

  def get_public_documents
    public_docs = (Document.select(:filename,:resolution,:realtime).where(deleted:false)).order(:realtime).all
     @arr = public_docs.map{|x| x.filename}.reverse
  end

  def checkpass(key)
    @current_user.password == key
  end

  get "/" do
    #genera un arreglo con el campo deseado
    get_public_documents
    erb :index, :layout => :layout_public_records
  end

  get '/user_documents' do
    user_docs = (Document.select(:filename,:resolution,:realtime).where(id: Notification.select(:document_id).where(user_id: session[:user_id], checked: false))).all
    @not_checkeds = user_docs.map{|x| x.filename}.reverse     #genera un arreglo con el campo deseado
    user_docs = (Document.select(:filename,:resolution,:realtime).where(id: Notification.select(:document_id).where(user_id: session[:user_id], checked: true))).all
    @checkeds = user_docs.map{|x| x.filename}.reverse
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
    ds = Document.select(:filename,:resolution,:realtime).where(fk_users_id: session[:user_id],deleted: false)
    @arr = ds.map{|x| x.filename}.reverse     #genera un arreglo con el campo deseado
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
      get_documents_bydoc(@record)
      erb:tagg
    elsif params[:search]
      ds = Document.select(:filename,:resolution,:realtime).where(resolution: params[:search],deleted: false)
      @arr = ds.map{|x| x.filename}.reverse
      if @arr[0] == nil
        @not_found_docs = "No se encontraron actas con dicha resolución.."
      end
      erb:myrecords , :layout => :layout_loged_menu
    end 
  end


  post '/tagg' do
    @tagged = params["tagg"]
    docc = Document.find(id: params["doc"])
    if @tagged != nil
      @tagged.map{|x| tagg_user(x,docc)} #tagged involved users
    end
    docc.update(description: params["description"], resolution: params["resolution"])
    redirect "/myrecords"
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
      set_user
      alert_notification
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
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    @arr= orderbydate.map{|x| x.filename}.reverse
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
    set_user
    erb:assign , :layout => :layout_loged_menu
  end

  get '/assign' do
    erb :assign , :layout => :layout_loged_menu
  end

  get '/sign_in' do  #sesion iniciada get
    get_public_documents
    if session[:user_id]
      set_user
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
    set_user
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
    user = User.new(surname: params["surname"], category: "user",  name: params["name"], username: params["username"], dni: params["dni"], password: params["key"], email: params["email"] )
    if user.save
      redirect "/"
    else
      [500, {}, "Internal server Error"]
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
    document = Document.new(resolution: params ["resolution"],path: "/file/#{params["path"]}",filename: params["filena"], description: params["description"], realtime: params["realtime"], fk_users_id: @current_user.id)
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
      deleting_doc.update(deleted: true) #delete from db
      #File.delete("public/file/#{name}") #delete from system
    else
      "cannot delete this Doc"
    end
  end

  def tagg_user(usr,document)
    user_tagg = User.find(dni: usr)
    if user_tagg != nil
      document.add_user(user_tagg)
    end
  end

  def get_documents_bydoc(doc)
    @dni_docc = User.select(:dni).where(id: Notification.select(:user_id).where(document_id: doc.id))
  end


## Pruebas para ver las tablas

  get "/prueba" do
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
    #user.update category: 'admin'
    #PARA MOSTRAR UN REGISTRO
    #usuario = User.first(id:2)
    #usuario.update(category:"admin")
    #usuario = User.first(id: session[:user_id])
    #u = usuario.name
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
