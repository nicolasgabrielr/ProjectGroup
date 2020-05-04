require 'json'
require './models/init.rb'
include FileUtils::Verbose

class App < Sinatra::Base

  configure do
    #enable :logging   si uso esto se me rompe porqueeeee?
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
    erb :index
  end

  post '/sign_in' do #inicio de sesion
    #filtra la tabla 
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
    usuario = User.find(email: params["email"])
    if usuario.password == params["password"]
      session[:user_name] = usuario.name
      session[:user_category]=usuario.category
      session[:user_id] = usuario.id
      session[:user_password] = usuario.password
      set_user
      erb :loged
    else
      erb :index
    end
  end

  def checkpass(key)
    session[:user_password] == key
  end

  post '/assign' do #asignacion de admin o super admin
    @band
    #filtra la tabla 
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
    if (session[:user_category] == "admin" || session[:user_category] == "superAdmin")
      usuario = User.find(email: params["emailnewAdmin"])
      if usuario != nil && checkpass(params["passwordActual"])
        if params[:admin] == 'Asignar Administrador'
          usuario.update(category:"admin")  
        else 
            usuario.update(category:"superAdmin")
        end
        @band = "¡El Administrador ha sido cargado con exito!"
      else
        @band = "No se pudo cargar el Administrador."
      end
      set_user
      erb:assign
    else 
      "no tienes permisos suficientes"
    end
  end

  get '/assign' do
    set_user
    erb :assign
  end 

  get '/sign_in' do  #sesion iniciada get
    if session[:user_id]
      set_user
      erb :loged
    else
      erb :index
    end
  end


  get '/sign_out' do  #cierre de sesion
      session.clear
      erb:index
  end


  get "/notificationlist" do
    erb:notificationlist
  end


  get "/index" do
    #filtra la tabla 
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
    session.clear
    erb :index
  end


  get "/about" do
    erb:about
  end


  get '/newUser' do
    erb:newUser
  end

  get '/mydata' do
    erb:mydata
  end

  get '/modifyemail' do
    erb:modifyemail
  end


  get '/uploadrecord' do  #carga de ducumentos
    if (session[:user_category] == "admin" || session[:user_category] == "superAdmin")
      erb:uploadrecord
    else
    #filtra la tabla 
    orderbydate=Document.select(:filename,:resolution,:realtime).order(:realtime).all
    #genera un arreglo con el campo deseado
    @arr= orderbydate.map{|x| x.filename}.reverse
      erb:index
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

  post '/load' do   #vista previa del documento para extraer datos y tags
    if (session[:user_category] == "admin" || session[:user_category] == "superAdmin")
      tempfile = params[:pdf][:tempfile]
      @filename = params[:pdf][:filename]
      cp(tempfile.path, "public/file/#{@filename}")
      @src =  "/file/#{@filename}"
      @realtime=Time.now
      erb :uploadrecord
    else
      erb:index
    end
  end

  post '/upload' do     #cargar documetos a la base de datos (supongo que tags tambien)
    if (session[:user_category] == "admin" || session[:user_category] == "superAdmin")
      erb :uploadrecord
      request.body.rewind
      hash = Rack::Utils.parse_nested_query(request.body.read)
      params = JSON.parse hash.to_json
      document = Document.new(resolution: params ["resolution"],path: params["path"],filename: params["filena"], description: params["description"], realtime: params["realtime"] )
      if document.save
        redirect "/uploadrecord"
      else
        [500, {}, "Internal server Error"]
      end
    else
      erb:index
    end
  end

  def set_user
    case session[:user_category]
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
    #PARA MODIFICAR UN REGISTRO
    #user = User.last
    #user.update category: 'admin'

    #PARA MOSTRAR UN REGISTRO
    #usuario = User.first(id:2)
    #usuario.update(category:"admin")

    #usuario = User.first(id: session[:user_id])
    #u = usuario.name

    Document.all.to_s
  end


end
