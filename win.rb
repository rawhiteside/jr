require 'ffi'

module Win
  extend FFI::Library

  CROSS_HAIR_CURSOR_ID = 32515

  class POINT < FFI::Struct
    layout :x, :long,
           :y, :long
  end

  ffi_lib 'user32'
  ffi_convention :stdcall

  attach_function :GetCursorPos, [ :pointer ], :void
  attach_function :GetCursor, [  ], :long
  attach_function :WindowFromPoint, [ POINT.by_value ], :pointer

  attach_function :SetCursor, [:pointer], :pointer

  attach_function :LoadCursorA, [:pointer, :long], :pointer

  attach_function :GetCapture, [], :pointer
  attach_function :SetCapture, [:pointer], :pointer
  attach_function :ReleaseCapture, [], :void



  ffi_lib 'kernel32'
  attach_function :GetLastError, [], :long

end

loop do
  sleep 1
  p Win.GetCursor
end

# point = Win::POINT.new
# p [point[:x], point[:y]]
# Win.GetCursorPos(point)
# p [point[:x], point[:y]]
# p Win.WindowFromPoint(point)
# p 



