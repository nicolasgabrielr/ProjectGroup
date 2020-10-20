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
        logger.info(user)
        @connection = {user: user, socket: ws}
        ws.onopen do
          settings.sockets << @connection
        end
      end
    end
  end

  def update_number_notifications_with_ws
    settings.sockets.each{|s| alert_notification(s[:user])
    s[:socket].send(@alert.to_s)
  }
  end

  post '/tagg' do
   @tagged = params["tagg"]
   document = Document.find(id: params["doc"])
   if @tagged != nil
     @tagged.map{|u| tagg_user(u,document)}
   end
   document.update(description: params["description"], resolution: params["resolution"])
   update_number_notifications_with_ws
   redirect "/myrecords"
  end


  superAdmin_Pages = ['/assign']
  admin_Pages = ['/tagg', '/upload', '/load', '/uploadrecord']
  public_Pages = ['/index', '/sign_in', '/', '/about', '/newUser', '/tablas']

  before do
    request.path_info
    if user_not_logged_in? && !public_Pages.include?(request.path_info)
      redirect '/index'
    elsif session[:user_id]
      @current_user = User.find(id: session[:user_id])
      alert_notification(session[:user_id])
      set_menu
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
    @current_user.category != "superAdmin"
  end

  def not_authorized_category_for_user?
    @current_user.category != "superAdmin" && @current_user.category != "admin"
  end

  def set_menu
    redirect '/index' if user_not_logged_in?
    case @current_user.category
      when "superAdmin" then
        show_super_admin
      when "admin" then
        show_admin
      else
        show_user
      end
        @usuario = session[:user_name]
  end

  def show_super_admin
    @admin = "visible"
    @superAdmin = "visible"
  end

  def show_admin
    @admin = "visible"
    @superAdmin = "hidden"
  end

  def show_user
    @admin = "hidden"
    @superAdmin = "hidden"
  end

  def get_public_documents
    public_docs = Document.deleteds(false)
    @arr = documents_array(public_docs)
  end

  def checkpass(key)
    @current_user.password == key
  end

  get '/user_documents' do
    user_docs = Document.by_ids(Notification.documents_id_uncheckeds_by_user(session[:user_id]))
    @not_checkeds = documents_array(user_docs)
    user_docs = Document.by_ids(Notification.documents_id_checkeds_by_user(session[:user_id]))
    @checkeds = documents_array(user_docs)
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
    update_number_notifications_with_ws
    redirect '/user_documents'
  end

  get '/myrecords' do
    ds = Document.by_user(session[:user_id])
    @arr = @arr = documents_array(ds)
    get_initial_and_final_date
    erb:myrecords , :layout => :layout_loged_menu
  end

  post '/myrecords' do
    if params[:delete]
      delete_document(params["elem"])
      update_number_notifications_with_ws
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

 def search_record (resolution,ini_d,end_d,author)
    get_initial_and_final_date
    ini_d == "" ? ini_d = @initial_date : "";
    end_d == "" ? end_d = @end_date : "";
    resolution != "" ?
      @arr = documents_array(Document.by_resolution_like(resolution)) :
      search_record_by_date_and_author(ini_d,end_d,author);
    if @arr[0] == nil
      @not_found_docs = "No se encontraron actas relacionadas con su busqueda.."
    end
  end

  def search_record_by_date_and_author(ini_d,end_d,author)
    ds = []
    author != "" and User.find(username: author) ?
     ds = Document.by_date_and_user(ini_d, end_d, user_by_author.id) :
     ds = Document.by_date(ini_d, end_d);
    @arr = documents_array(ds)
  end

  post '/search_record' do
    search_record(params[:resolution],params[:initiate_date],params[:end_date],params[:author])
    erb:myrecords , :layout => :layout_loged_menu
  end

  def alert_notification(user)
    @alert = Notification.number_of_uncheckeds_for_user(user)
  end

  def tagg_user(dni,document)
    if User.find(dni: dni)
      if User.find(dni: dni) and !Notification.find(user_id: User.find(dni: dni).id, document_id: document.id)
        document.add_user(User.find(dni: dni))
      end
    else
      not_user_tagg = add_generic_user(dni.to_s, dni)
      not_user_tagg.save ? document.add_user(not_user_tagg) :
        [500, {}, "Internal server Error"];
    end
  end

  def add_generic_user (string_dni, dni)
    User.new(
      surname: string_dni,
      category: "not_user",
      name: string_dni,
      username: string_dni,
      dni: dni,
      password: "not_user#{string_dni}",
      email: "#{string_dni}@email.com")
    not_user_tagg.save ? document.add_user(not_user_tagg) :
      [500, {}, "Internal server Error"];
  end

  get '/loged' do
    get_public_documents
    erb:loged , :layout => :layout_loged_menu
  end

  post '/loged' do
    if params[:dni] != "" && params[:dni] != nil
      user = User.find(dni: params[:dni])
      if user
        public_docs = user.documents(deleted: false)
        @arr = documents_array(public_docs)
      else
        get_public_documents
      end
    elsif (params[:resolution] != "" || params[:initiate_date] != "" || params[:end_date] != "")
        search_record(params[:resolution],params[:initiate_date],params[:end_date],"")
     else
        get_public_documents
    end
      erb:loged , :layout => :layout_loged_menu
  end

  post '/sign_in' do
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

  post '/assign' do
    docs = Document.order_by_date
    @arr= documents_array(docs)
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

  get '/sign_in' do
    get_public_documents
    if session[:user_id]

      set_menu
      erb:loged , :layout => :layout_loged_menu
    else
      erb:index , :layout => :layout_public_records
    end
  end

  get '/sign_out' do
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

  post "/index" do
    if params[:dni] != "" && params[:dni] != nil
      user = User.find(dni: params[:dni])
      if user
        public_docs = user.documents_dataset.where(deleted: false).reverse_order{documents[:realtime]}
        @arr = documents_array(public_docs)
      else
        get_public_documents
      end
    elsif ((params[:resolution] != "" && params[:resolution] != nil) ||
     (params[:initiate_date] != "" && params[:initiate_date] != nil) ||
      (params[:end_date] != "" && params[:end_date] != nil))
        search_record(params[:resolution],params[:initiate_date],params[:end_date],"")
     else
        get_public_documents
    end
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
  get '/modifyData' do
    erb:modifyData , :layout => :layout_loged_menu
  end

  post '/modifyData' do
    @current_user.update(name: params["newName"])
    @current_user.update(surname: params["newSurname"])
    @band = "¡Datos actualizados corretamente!"
    set_menu
    erb:modifyData , :layout => :layout_loged_menu
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

  get '/uploadrecord' do
      erb:uploadrecord
  end

  post '/newUser' do
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    pre_load_user = User.find(dni: params["dni"])
    exist_username = User.find(username: params["username"])
    exist_email = User.find(email: params["email"])
      if pre_load_user
        if pre_load_user.category == "not_user"
          update_pre_load_user(pre_load_user,params)
          redirect "/"
        else
          [500, {}, "El usuario ya existe"]
        end
      else
        if (exist_username)
          @log_err = "El usuario ingresado ya existe"
        elsif (exist_email)
          @log_err = "El email ingresado ya existe"
        else
          user = add_new_user(params)
          if user.save
            redirect "/"
          else
            [500, {}, "Internal server Error"]
          end
        end
        erb:newUser
      end
  end

  def add_new_user(data)
    User.new(
      surname: data["surname"],
      category: "user",
      name: data["name"],
      username: data["username"],
      dni: data["dni"],
      password: data["key"],
      email: data["email"]
    )
  end

  def update_pre_load_user(user,data)
    user.update(
      surname: data["surname"],
      category: "user",
      name: data["name"],
      username: data["username"],
      dni: data["dni"],
      password: data["key"],
      email: data["email"]
    )
  end


  get '/uploadImg' do
    erb:modifyphoto
  end

  post '/uploadImg' do
    if @current_user.imgpath != nil && File.exist?("public#{@current_user.imgpath}")
      File.delete("public#{@current_user.imgpath}")
    end
    tempfile = params[:myImg][:tempfile]
    @filename = params[:myImg][:filename]
    cp(tempfile.path, "public/usr/#{@filename}")
    @current_user.update(imgpath: "/usr/#{@filename}")
    redirect "/mydata"
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
    @tagged = params["tagg"]
    cp("public/temp/#{params["path"]}","public/file/#{params["path"]}")
    document = Document.new(
      resolution: params ["resolution"],
      path: "/file/#{params["path"]}",
      filename: params["filena"],
      description: params["description"],
      realtime: params["realtime"],
      user_id: @current_user.id
    )
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
      deleting_doc.update(deleted: true)
    else
      "cannot delete this Doc"
    end
  end

  def documents_array(documents)
      documents.map{|x|
        file = {:filename => x.filename,
          :resolution => x.resolution,
          :description => x.description ,
          :date => x.realtime.strftime("%d/%m/%y") }
      }
  end

  def get_initial_and_final_date
    @initial_date = Document.first.realtime.strftime("%Y-%m-%d")
    @end_date = ((Time.now) + 86400).strftime("%Y-%m-%d")
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
    User.each { |u| @out+= u.email + "--" + u.dni.to_s + "--" + u.password.to_s + "--" + u.category.to_s +  "<br/>" }
    @out +="<br/>"
    Document.each { |d| @out+=d.path+"<br/>" }
    @out +="<br/>"+ "listado de documentos ----> usuarios" + "<br/>"
    Document.each { |d| @out+= d.path + " ------relacionado con----- " + d.users.to_s + "<br/>" }
    @out +="<br/>"+ "listado de usuarios ----> documentos" + "<br/>"
    User.each { |u| @out+= u.email + " -----relacionado con----- " + u.documents.to_s + "<br/>" }
    @out +="<br/>"

  end

end
