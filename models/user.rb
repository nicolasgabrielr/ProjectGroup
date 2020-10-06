class User < Sequel::Model
  plugin :validation_helpers
  def validate
    super
    validates_presence %i[email name dni surname password username]
    validates_unique %i[email username dni]
    validates_format(/\A.*@.*\..*\z/, :email, message: 'is not a valid email')
    validates_inclusion_of :dni, in: 100_000..999_999_999, message: 'is not a valid dni'
  end
  many_to_many :documents
  one_to_many :notifications
end
