class App < Sinatra::Base
  get "/" do
    erb:index
  end
  get "/logeduser" do
    erb:logeduser
  end
  get "/logedadmin" do
    erb:logedadmin
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
  get "/templatetest" do
    erb:templatetest
  end
  post "/login" do
    if params[:key]=="123"
    "te has logueago correctamente #{params[:user]}"
     erb :logeduser
    else
     erb :logedadmin
    end
 end
end
