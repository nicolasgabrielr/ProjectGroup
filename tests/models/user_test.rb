require File.expand_path '../../test_helper.rb', __FILE__
class UserTest < MiniTest::Unit::TestCase
  MiniTest::Unit::TestCase
  def setup
    # Arrange
    @user = User.new
    @user1 = User.new
    # Act
    @user.name = 'Jeremy'
    @user.email = 'email@email.com'
    @user.dni = 99999999
    @user.surname = 'Evans'
    @user.password = '1234'
    @user.username = 'jevans'

    @user1.name = 'aaa'
    @user1.email = 'uncorreo@zzz.com'
    @user1.dni = 33444555
    @user1.surname = 'ppp'
    @user1.password = 'asas'
    @user1.username = 'bbb'

  end
    def test_username_existence
      @user.username = nil
      # Assert
      assert_equal @user.valid?,false
    end

    def test_name_existence
      @user.name = ""
      # Assert
      assert_equal @user.valid?,false
    end

    def test_surname_existence
      @user.surname = ""
      # Assert
      assert_equal @user.valid?,false
    end

    def test_dni_existence
      @user.dni = nil
      # Assert
      assert_equal @user.valid?,false
    end

    def test_email_existence
      #Act
      @user.email = nil
      # Assert
      assert_equal @user.valid?,false
    end


    def test_email_format_invalid
        #Act
      @user.email = "sasas"  
        #Assert
      assert_equal @user.valid?, false
    end

    def test_email_format_valid
        #Act
      @user.email = "email@eamil.com"
        #Assert
      assert_equal @user.valid?, true
    end


end
