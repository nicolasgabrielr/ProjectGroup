class User < Sequel::Model
  plugin :validation_helpers
  def validate
   super
    validates_presence [:email, :name, :dni, :surname, :password, :username]
    validates_unique [:email, :username, :dni]
    validates_format /\A.*@.*\..*\z/, :email, message: 'is not a valid email'
  end
  many_to_many :documents
end
