class User < Sequel::Model
  plugin :validation_helpers
  def validate
   super
    validates_presence :username, message: "A username required"
    validates_presence :email, message: "A email required"
    validates_presence :name, message: "A name required"
    validates_presence :dni, message: "A dni required"
    validates_presence :surname, message: "A surname required"
    validates_presence :password, message: "A password required"
    validates_unique [:email, :username, :dni]
    validates_format /\A.*@.*\..*\z/, :email, message: 'is not a valid email'
  end
  many_to_many :documents
  one_to_many :notifications
end
