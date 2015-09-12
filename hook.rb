require 'ffi'

module HookProc

  extend FFI::Library
  ffi_lib :user32, :kernel32
  ffi_convention :stdcall

  # Hook reference
  #   http://msdn.microsoft.com/en-us/library/windows/desktop/ms632589(v=vs.85).aspx
  #
  callback :procedure, [ :int, :uint, :long ], :int
  attach_function :callNextHookEx, :CallNextHookEx, [ :pointer, :int, :uint, :long ], :int, :blocking => true
  attach_function :setWindowsHookEx, :SetWindowsHookExA, [ :int, :procedure, :uint, :uint ], :pointer
  attach_function :unhookWindowsHookEx, :UnhookWindowsHookEx, [ :pointer ], :bool
  attach_function :getCurrentThreadId, :GetCurrentThreadId, [], :int
  attach_function :getLastError, :GetLastError, [], :int

  @hhook = nil
  @tid = getCurrentThreadId

  # KeyboardProc callback function
  #   http://msdn.microsoft.com/en-us/library/windows/desktop/ms644984(v=vs.85).aspx
  #
  KeyboardProc = Proc.new() { |nCode, wParam, lParam|
    puts wParam
    state = lParam >> 30 # 0 - onKeyDown, -1 - onKeyUp, 1 - onKeyExtended
    unhook if wParam == 0x1b and state == 0 # on escape key down

    # Pass the hook information to the next hook procedure.
    callNextHookEx(nil, nCode, wParam, lParam)
    # May return a non-zero value to prevent the system from passing the message
    # to the target window procedure.
    1
  }

  class << self

    def hook
      return false if @hhook != nil
      @hhook = setWindowsHookEx(2, KeyboardProc, 0, @tid)
      puts "hook called!  tid is #{@tid}, hhook is #{@hhook}"
      puts "getLastError: #{getLastError}"
      true
    end

    def unhook
      return false if @hhook == nil
      unhookWindowsHookEx(@hhook)
      puts "unhook called!  tid is #{@tid}, hhook is #{@hhook}"
      puts "getLastError: #{getLastError}"
      puts 'unhook called!'
      @hhook = nil
      true
    end

    def status
      @hhook != nil
    end

  end # class << self

end # module HookProc

#puts "calling hooook"
#HookProc.hook
#puts "back from hoook"
#sleep 5
#HookProc.unhook
