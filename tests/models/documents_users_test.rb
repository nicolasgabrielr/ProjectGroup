require File.expand_path '../../test_helper.rb', __FILE__
class UserTest < MiniTest::Unit::TestCase
  MiniTest::Unit::TestCase
 def setup
  @user = User.new

  @user.name = 'Jeremy'
  @user.email = 'email@email.com'
  @user.dni = 99999999
  @user.surname = 'Evans'
  @user.password = '1234'
  @user.username = 'jevans'

  @doc1 = Document.new(resolution: "resolution1",path: "/file/filename1.pdf", filename: "name1", description: "description", realtime: "02020202")
  @doc2 = Document.new(resolution: "resolution2",path: "/file/filename2.pdf", filename: "name2", description: "description", realtime: "02020203")
 end

 def test_has_many_documents_when_there_are_no_documents
  assert_equal @user.documents, []
 end

 def test_has_many_document_with_two_documents
    @user.documents << @doc1
    @user.documents << @doc2
    assert_equal @user.documents, [@doc1, @doc2]
 end
end
