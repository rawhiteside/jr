class Timer
  def self.time_this
    start = Time.now
    yield
    Time.now - start
  end
end
