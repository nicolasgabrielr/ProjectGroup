require 'json'
require './models/init.rb'
require 'sinatra-websocket'
require './controllers/account_controller.rb'
require './controllers/admin_controller.rb'
require './controllers/notification_controller.rb'
require './controllers/base_controller.rb'
require './controllers/document_controller.rb'
require './services/account_service'
require './services/document_service'

include FileUtils::Verbose

class App < Sinatra::Base
  configure do
    enable :logging
    enable :sessions
    set :session_fail, '/'
    set :session_secret, 'otro secret pero dificil y abstracto'
    set :sessions, true
    set :server, 'thin'
    set :sockets, []
  end

  $ws = []
  superAdmin_Pages = ['/assign']
  admin_Pages = ['/tagg', '/upload', '/load', '/uploadrecord']
  public_Pages = ['/index', '/sign_in', '/', '/about', '/newUser', '/tablas']

  use Account_controller
  use Admin_controller
  use Base_controller
  use Notification_controller
  use Document_controller




  before do
    request.path_info
    if user_not_logged_in? && !public_Pages.include?(request.path_info)
      redirect '/index'
    elsif session[:user_id]
      @current_user = User.find(:id => session[:user_id])
      alert_notification(session[:user_id])
      @usr = Account_service.set_menu session[:user_id], @current_user
      if not_authorized_category_for_admin? && superAdmin_Pages.include?(request.path_info)
        redirect '/index'
      elsif not_authorized_category_for_user? && admin_Pages.include?(request.path_info)
        redirect '/index'
      end
    end
  end

  def alert_notification(user)
		@alert = Notification.number_of_uncheckeds_for_user(user)
	end

  def user_not_logged_in?
    !session[:user_id]
  end

  def not_authorized_category_for_admin?
    @current_user.category != 'superAdmin'
  end

  def not_authorized_category_for_user?
    @current_user.category != 'superAdmin' && @current_user.category != 'admin'
  end

  def init_folders
    folders_list = ['public/usr/', 'public/temp/', 'public/file/']
    folders_list.each do |f|
      Dir.mkdir(f) unless Dir.exist?(f)
    end
  end

  get '/' do
    init_folders
    if !request.websocket?
      @arr = Document_service.documents_array(Document.deleteds(false))
      erb :index, :layout => :layout_public_records
    else
      request.websocket do |ws|
        user = session[:user_id]
        logger.info(user)
        @connection = { :user => user, :socket => ws }
        ws.onopen do
          settings.sockets << @connection
          $ws = settings.sockets
        end
      end
    end
  end

end
