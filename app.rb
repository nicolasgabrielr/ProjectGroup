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
    if !session[:user_id] && request.path_info != '/index' && request.path_info != '/sign_in' && request.path_info != '/' && request.path_info != '/about' && request.path_info != '/newUser'
      redirect '/index'
    elsif session[:user_id]
      @current_usr = User.find(id: session[:user_id])
      set_user
      if @current_usr.category != "superAdmin" && request.path_info == '/assign'
        redirect '/index'
      elsif @current_usr.category != "superAdmin" && @current_usr.category != "admin" && (request.path_info == '/tagg' || request.path_info == '/upload'|| request.path_info == '/load'|| request.path_info == '/uploadrecord')
        redirect '/index'
      end
    end
  end

  def set_user
    case @current_usr.category
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


  def checkpass(key)
    @current_usr.password == key
  end

  get "/" do
    #filtra la tabla
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
    erb :index, :layout => :layout_public_records
  end

  get '/myrecords' do
    ds = Document.select(:filename,:resolution,:realtime).where(fk_users_id: session[:user_id])
    @arr= ds.map{|x| x.filename}.reverse     #genera un arreglo con el campo deseado
    erb:myrecords , :layout => :layout_loged_menu
  end


  post '/myrecords' do
    if params[:delete]
      deleteDoc(params["elem"]) #elem is name of document
      redirect "/myrecords"
    else
      "No se pudo eliminar el documento"
    end
    if params[:tagg]

      @record=Document.find(filename: params["elem"])
      @record.path.to_s
      erb:tagg
    end
  end

  post '/tagg' do
    @tagged = params["tagg"]
    docc = Document.find(id: params["doc"])
    if @tagged != nil
      @tagged.map{|x| taggingUsr(x,docc)} #tagged involved users
    end
    docc.update(description: params["description"], resolution: params["resolution"])
    redirect "/myrecords"
  end

  post '/sign_in' do #inicio de sesion
    #filtra la tabla
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr = orderbydate.map{|x| x.filename}.reverse
    usuario = User.find(email: params["email"])
    if usuario.password == params["password"]
      session[:user_name] = usuario.name
      session[:user_id] = usuario.id
      @current_usr = User.find(id: session[:user_id])
      set_user
      erb:loged , :layout => :layout_loged_menu
    else
      redirect "/"
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
     #filtra la tabla
    orderbydate=Document.select(:filename,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
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
    #filtra la tabla
    orderbydate=Document.select(:filename,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
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
    @username = @current_usr.name
    @foto = @current_usr.imgpath
    erb:mydata , :layout => :layout_loged_menu
  end

  get '/modifyemail' do
    erb:modifyemail , :layout => :layout_loged_menu
  end

  post '/modifyemail' do
    if checkpass(params["passwordActual"])
      @current_usr.update(email: params["emailNew1"])
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
      @current_usr.update(password: params["passwordNew1"])
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
    if @current_usr.imgpath != nil && File.exist?("public#{getCurrentUser.imgpath}")
      File.delete("public#{getCurrentUser.imgpath}")
    end
    tempfile = params[:myImg][:tempfile]
    @filename = params[:myImg][:filename]
    cp(tempfile.path, "public/usr/#{@filename}")
    @current_usr.update(imgpath: "/usr/#{@filename}")
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
      document = Document.new(resolution: params ["resolution"],path: "/file/#{params["path"]}",filename: params["filena"], description: params["description"], realtime: params["realtime"], fk_users_id: @current_usr.id)
      if document.save
        @record = document
        erb:tagg
      else
        [500, {}, "Internal server Error"]
      end
  end

  def deleteDoc(name)
    if File.exist?("public/file/#{name}")
      Document.find(filename: name).delete #delete from db
      File.delete("public/file/#{name}") #delete from system
    else
      "cannot delete this Doc"
    end
  end


  def taggingUsr(usr,document)
    user_tagg = User.find(dni: usr)
    if user_tagg != nil
      document.add_user(user_tagg)
    end
  end



## Pruebas para ver las tablas

  get "/prueba" do
    #pp=Document.where(users: User[28]).all
    #pp.last.path
    #User[28].documents
    pp =DB['select document_id from users inner join documents_users on users.id = documents_users.user_id where user_id = 28 and see_check = false']
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
    #User.all.to_s
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
