require 'test/unit'
require 'm_choose_n.rb'

class MChooseNTest < Test::Unit::TestCase
  def test_3_2
    expected = [[0,1], [0,2], [1,2]]
    got = []
    MChooseN.new.each(3,2) do |arr|
      got << arr
    end
    assert_equal(expected, got)
  end

  def test_4_3
    expected = [[0, 1, 2], [0, 1, 3], [0, 2, 3], [1, 2, 3]]
    got = []
    MChooseN.new.each(4,3) do |arr|
      got << arr
    end
    assert_equal(expected, got)
  end

  def test_4_2
    expected = [[0, 1], [0, 2], [0, 3], [1, 2], [1, 3], [2, 3]]
    got = []
    MChooseN.new.each(4,2) do |arr|
      got << arr
    end
    assert_equal(expected, got)
  end

  def test_10_4
    count = 0
    MChooseN.new.each(10,4) do |arr|
      count += 1
    end
    numerator = 10*9*8*7*6*5*4*3*2*1
    denom = (4*3*2*1)*(6*5*4*3*2*1)
    expected = numerator / denom
    assert_equal(expected, count)
  end
end
