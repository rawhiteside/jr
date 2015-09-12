import java.util.concurrent.locks.ReentrantLock

class JMonitor < ReentrantLock
  def synchronize
    lock
    begin
      yield
    ensure
      unlock
    end
  end
end
