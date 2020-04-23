require 'json'
require './models/init.rb'

class App < Sinatra::Base

  get "/prueba" do
    #User[19].delete

    #PARA MODIFICAR UN REGISTRO
    #user = User.last
    #user.update category: 'superAdmin'

    #PARA MOSTRAR UN REGISTRO
    #usuario = User.first(id:19)
    #u = usuario.name


    User.all.to_s
  end

  get "/" do
    erb:index
  end

  get "/index" do
    erb:index
  end

  get "/about" do
    erb:about
  end

  get '/newUser' do
    erb:newUser
  end

  get '/uploadrecord' do
    erb:uploadrecord
  end


  post '/newUser' do
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



  post "/loged" do
    @admin = "hidden"
    @superAdmin = "hidden"
    user = User.last #deberia ver username:params[:username]  email: params[:email]
                     #creo que tengo que crear un index en cada columna para buscar

    if params[:key] == user.password
      if user.category == "admin"
       @admin = "submit"
     elsif user.category =="superAdmin"
       @admin = "submit"
       @superAdmin = "submit"
      end
    else
      "contraseña incorrecta"
    end

    erb :loged
  end


end
