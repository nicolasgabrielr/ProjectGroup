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

	def self.current_user(session)
		User.find(:id => session[:user_id])
  end

  def self.message(user, params)
		if user.password == params['passwordActual']
	 	 usuario = User.find(:email => params['emailnewAdmin'])
	 	 if params[:dUser] && !usuario.nil?
	 		 usuario.destroy
	 		 msg = '¡El usuario ha sido eliminado con Exito!'
	 	 else
	 		 msg = '¡El usuario no existe o no se pudo eliminar!'
	 	 end
	 	 if params[:admin]
	 		 usuario.update(:category => 'admin')
	 		 msg = '¡El Administrador ha sido cargado con exito!'
	 	 elsif params[:sAdmin]
	 		 usuario.update(:category => 'superAdmin')
	 		 msg = '¡El Administrador ha sido cargado con exito!'
	 	 end
	  else
	 	 msg = 'El password es incorrecto o el usuario no existe'
	  end
		return msg
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

  def self.set_menu(session, user)
		raise ArgumentError.new('No hay una sesion abierta') if !session
    #redirect '/index' if !session
    user = User.find(:id => session)
    case user.category
    when 'superAdmin'
			admin = 'visible'
	    superAdmin = 'visible'
    when 'admin'
			admin = 'visible'
	    superAdmin = 'hidden'
    else
			admin = 'hidden'
	    superAdmin = 'hidden'
    end
    usuario = session
		return { :admin => admin, :superAdmin => superAdmin, :usuario => usuario }
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

	def self.logged_page (user)
		if user == nil
      raise ArgumentError.new('no esta logueado')
		end
  end

	def self.loged(params)
		if params[:dni] != '' && !params[:dni].nil?
			user = User.find(:dni => params[:dni])
			if user
				public_docs = user.documents(:deleted => false)
				@arr = General_service.documents_array(public_docs)
			else
				@arr = General_service.documents_array(Document.deleteds(false))
			end
		elsif params[:resolution] != '' || params[:initiate_date] != '' || params[:end_date] != ''
			search_record(params[:resolution], params[:initiate_date], params[:end_date], '')
		else
			@arr = General_service.documents_array(Document.deleteds(false))
		end
	end

	def self.modify_data(user, params, msg)
		user.update(:name => params['newName'])
    user.update(:surname => params['newSurname'])
		msg = '¡Datos actualizados corretamente!'
	end

	def self.modify_email(user, params, msg)
		if checkpass(params['passwordActual'], user)
			user.update(:email => params['emailNew1'])
			msg = '¡El email ha sido Actualizado con exito!'
		else
			msg = 'La contraseña o el email son Incorrectos!'
		end
	end

	def self.checkpass(key, user)
    user.password == key
  end

	def self.modify_password(user, params, msg)
		if checkpass(params['passwordActual'], user)
			user.update(:password => params['passwordNew1'])
			band = '¡El password ha sido Actualizado con exito!'
		else
			band = 'La contraseña ingresada es incorrecta'
		end
	end
end
