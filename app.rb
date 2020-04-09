class App < Sinatra::Base
  get "/" do
    erb:home

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
end
