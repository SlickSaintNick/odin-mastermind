class Test1
  attr_reader :test_val

  def initialize
    @test_val = "Test1.test_val's value"
  end
end

class Test2
  def initialize
    @test1 = Test1.new
  end

  def test_print
    p @test1.test_val
  end
end

test2 = Test2.new
test2.test_print
