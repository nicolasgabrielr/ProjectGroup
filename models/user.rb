class User < Sequel::Model
  def validate
   super
   errors.add(:name, "can't be empty") if name.empty?
   #validates_format /\A.*@.*\..*\z/, :email, message: 'is not a valid email'
  end
end
