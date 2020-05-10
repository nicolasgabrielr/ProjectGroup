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

  get "/" do
    #filtra la tabla
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
    erb :index, :layout => :layout_public_records
  end

  def deleteDoc(name)
    if File.exist?("public/file/#{name}")
      Document.find(filename: name).delete #delete from db
      File.delete("public/file/#{name}") #delete from system
    else
      "cannot delete this Doc"
    end
  end

  def getCurrentUser()
    current_usr = User.find(id: session[:user_id])
  end

  def checkpass(key)
    getCurrentUser.password == key
  end

  get '/myrecords' do
    set_user
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
    if (getCurrentUser.category == "admin" || getCurrentUser.category == "superAdmin")
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
    else
      erb:loged , :layout => :layout_loged_menu
    end
  end


  get '/assign' do
    set_user
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
    @username = getCurrentUser.name
    @foto = getCurrentUser.imgpath
    set_user
    erb:mydata , :layout => :layout_loged_menu
  end

  get '/modifyemail' do
    set_user
    erb:modifyemail , :layout => :layout_loged_menu
  end

  post '/modifyemail' do
    if checkpass(params["passwordActual"])
      getCurrentUser.update(email: params["emailNew1"])
      @band = "¡El email ha sido Actualizado con exito!"
    else
      @band = "La contraseña o el email son Incorrectos!"
    end
    set_user
    erb:modifyemail , :layout => :layout_loged_menu
  end

  get '/modifypassword' do
    set_user
    erb:modifypassword , :layout => :layout_loged_menu
  end

  post '/modifypassword' do
    if checkpass(params["passwordActual"])
      getCurrentUser.update(password: params["passwordNew1"])
      @band = "¡El password ha sido Actualizado con exito!"
    else
      @band = "La contraseña ingresada es incorrecta"
    end
    set_user
    erb:modifypassword , :layout => :layout_loged_menu
  end

  get '/modifyphoto' do
    erb:modifyphoto
  end

  get '/uploadrecord' do  #carga de ducumentos
    set_user
    if (getCurrentUser.category == "admin" || getCurrentUser.category == "superAdmin")
      erb:uploadrecord
    else
    #filtra la tabla
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
      erb:index , :layout => :layout_public_records
    end
  end

  post '/newUser' do   #cargar un nuevo usuario
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    user = User.new(surname: params["surname"], name: params["name"], username: params["username"], dni: params["dni"], password: params["key"], email: params["email"] )
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
    if getCurrentUser.imgpath != nil && File.exist?("public#{getCurrentUser.imgpath}")
      File.delete("public#{getCurrentUser.imgpath}")
    end
    tempfile = params[:myImg][:tempfile]
    @filename = params[:myImg][:filename]
    cp(tempfile.path, "public/usr/#{@filename}")
    getCurrentUser.update(imgpath: "/usr/#{@filename}")
    redirect "/mydata"
  end

  post '/load' do   #vista previa del documento para extraer datos y tags
    if (getCurrentUser.category == "admin" || getCurrentUser.category == "superAdmin")
      tempfile = params[:pdf][:tempfile]
      @filename = params[:pdf][:filename]
      cp(tempfile.path, "public/file/#{@filename}")
      @src =  "/file/#{@filename}"
      @realtime=Time.now
      erb :uploadrecord
    else
      erb:index , :layout => :layout_public_records
    end
  end

  post '/upload' do     #upload documents and taggs users
    if (getCurrentUser.category == "admin" || getCurrentUser.category == "superAdmin")
      erb :uploadrecord
      request.body.rewind
      hash = Rack::Utils.parse_nested_query(request.body.read)
      params = JSON.parse hash.to_json
      @tagged = params["tagg"]
      document = Document.new(resolution: params ["resolution"],path: params["path"],filename: params["filena"], description: params["description"], realtime: params["realtime"], fk_users_id: getCurrentUser.id)
      if document.save
        docc = Document.last
        @tagged.map{|x| docc.add_user(User.find(dni: x))} #tagged involved users
        redirect "/uploadrecord"
      else
        [500, {}, "Internal server Error"]
      end
    else
      erb:index , :layout => :layout_public_records
    end
  end

  def set_user
    case getCurrentUser.category
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


## Pruebas para ver las tablas

  get "/prueba" do
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

    User.all.to_s
  end


end
