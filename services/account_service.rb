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
      if exist_username
      	@log_err = 'El usuario ingresado ya existe'
        #raise ArgumentError.new('El usuario ingresado ya existe')
      elsif exist_email
      	@log_err = 'El email ingresado ya existe'
        #raise ArgumentError.new('El email ingresado ya existe')
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
			@log_err = 'Datos para crear el usuario incorrectos'
      #raise ValidationModelError.new("Datos para crear el usuario incorrectos", newUser.errors)
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

end

