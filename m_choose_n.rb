class MChooseN
  def each(max, n)
    arr = []
    n.times {|i| arr << i}
    loop do
      yield arr.dup
      arr = incr(arr, n-1, n, max)
      break unless arr
    end
  end

  def incr(arr, index, n, max)
    return nil if index < 0

    # Increment our value, and set all subsequent ones.
    v = arr[index] + 1
    index.upto(n-1) do |i|
      arr[i] = v
      v += 1
    end
    return arr if arr[n-1] < max
    return incr(arr, index - 1, n, max)
  end
end
