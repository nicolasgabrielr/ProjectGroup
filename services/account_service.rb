#require './exceptions/ValidationModelError.rb'
require './models/user.rb'
class Account_service

	def self.newUser(params)
		pre_load_user = User.find(:dni => params['dni'])
    exist_username = User.find(:username => params['username'])
    exist_email = User.find(:email => params['email'])
 		if pre_load_user && (pre_load_user.category == 'not_user')
	    update_pre_load_user pre_load_user, params
    else
      if exist_username || (pre_load_user && (pre_load_user.category != 'not_user'))
        raise ArgumentError.new('El usuario ingresado ya existe')
      elsif exist_email
        raise ArgumentError.new('El email ingresado ya existe')
      else
        add_new_user params
      end
    end
	end

	def self.add_new_user(data)
		newUser = User.new(
			:surname => data['surname'],
	  	:category => 'user',
	    :name => data['name'],
	    :username => data['username'],
	    :dni => data['dni'],
	    :password => data['key'],
	    :email => data['email']
	    )
		unless newUser.valid?
      raise ArgumentError.new('Datos para crear el usuario incorrectos')
    end
		newUser.save
	end

	def self.update_pre_load_user(user, data)
    user.update(
      :surname => data['surname'],
      :category => 'user',
      :name => data['name'],
      :username => data['username'],
      :dni => data['dni'],
      :password => data['key'],
      :email => data['email']
    )
  end

  def self.set_menu(session)
    redirect '/index' if !session
    @current_user = User.find(:id => session)
    case @current_user.category
    when 'superAdmin'
      show_super_admin
    when 'admin'
      show_admin
    else
      show_user
    end
    @usuario = session
  end

  def self.show_super_admin
    @admin = 'visible'
    @superAdmin = 'visible'
  end

  def self.show_admin
    @admin = 'visible'
    @superAdmin = 'hidden'
  end

  def self.show_user
    @admin = 'hidden'
    @superAdmin = 'hidden'
  end

  def self.sign_in(params,session)
    usuario = User.find(:email => params['email'])
    if !usuario.nil? && (usuario.password == params['password'])
      session[:user_name] = usuario.name
      session[:user_id] = usuario.id
    elsif usuario.nil?
      raise ArgumentError.new('El usuario ingresado no existe')
    else
      raise ArgumentError.new('La contraseña ingresada es incorrecta')
    end
  end

end