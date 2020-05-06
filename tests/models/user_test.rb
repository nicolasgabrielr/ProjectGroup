require File.expand_path '../../test_helper.rb', __FILE__
class UserTest < MiniTest::Unit::TestCase
  MiniTest::Unit::TestCase
  def setup
    # Arrange
    @user = User.new
    @user1 = User.new
    # Act
    @user.name = 'aaa'
    @user.email = 'miperrodinamita@pr.com'
    @user.dni = 24222222
    @user.surname = 'ppp'
    @user.password = 'asas'
    @user.username = 'aaa'

    @user1.name = 'aaa'
    @user1.email = 'uncorreo@zzz.com'
    @user1.dni = 33444555
    @user1.surname = 'ppp'
    @user1.password = 'asas'
    @user1.username = 'bbb'

  end
    def test_existence
      # Act
      a = @user.valid?  #TRUE
      @user.name = nil
      b = @user.valid?  #false !name
      @user.name = 'aaa'
      @user.email = nil
      c = @user.valid? #false !email
      @user.email = 'miperrodinamita@pr.com'
      @user.dni = nil
      d = @user.valid? #false !dni
      @user.dni = 24222222
      @user.surname = nil
      e = @user.valid?  #false !surname
      @user.surname = 'ppp'
      @user.password = nil
      f = @user.valid?  #false !password
      @user.password = 'asas'
      @user.username = nil
      g = @user.valid? #false !username
      @user.username = 'aaa'
      # Assert
      assert_equal !a || b || c || d || e || f || g, false
    end

    def test_email_format
      # Act
      @user.email = ''   #invalid email
      a =  @user.valid?  #false
      @user.email = 'qq' #invalid email
      b =  @user.valid? #false
      @user.email = 'qq@qq' #invalid email
      c =  @user.valid? #false
      @user.email = nil #invalid email
      d = @user.valid? #false
      @user.email = 'miperrodinamita@pr.com' #valid email
      # Assert
      assert_equal a || b || c || d, false  #false == false => true
    end
end
