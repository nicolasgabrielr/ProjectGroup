class App < Sinatra::Base

  get "/" do
    erb:index
  end

  get "/index" do
    erb:index
  end

  get "/notificationlist" do
    erb:notificationlist
  end

  get "/notificationdemo" do
    erb:notificationdemo
  end

  get "/about" do
    erb:about
  end

  get "/loged" do
    "solo deberia cargar nuevamente la Pagina"
  end

  post "/loged" do
    @name = params[:user]
    @admin = "hidden"
    @superAdmin = "hidden"
    if params[:key]=="123"
     @admin = "submit"
    elsif params[:key]=="111"
     @admin = "submit"
     @superAdmin = "submit"
    end
    erb :loged
  end

  get "/:doc" do
    "aca se muestra el  #{params[:doc]} "
  end

end
