  def dib_rectangle(x_screen, y_screen, width, height)
    # Source dc
    hdcScreen = HDCScreen
    hdcMem = CreateCompatibleDC.call(hdcScreen)
    hbmp = CreateCompatibleBitmap.call(hdcScreen, width, height)
    hbmpOld = SelectObject.call(hdcMem, hbmp)

    BitBlt.call(hdcMem, 0, 0, width, height, hdcScreen, x_screen, y_screen, SRCCOPY)
    SelectObject.call(hdcMem, hbmpOld)


    bi = BitmapInfoHeader.new
    bi.update('biSize' => bi.bin_size, 'biWidth' => width, 'biHeight' => height,
	      'biPlanes' => 1, 'biBitCount' => 32, 'biCompression' => BI_RGB)

    bitmap_info = bi.to_binary

    bit_buf = ' ' * (4 * width * height)
    n = GetDIBits.call(hdcMem, hbmp, 0, height, bit_buf, bitmap_info, DIB_RGB_COLORS)
    puts "GetDIBits returned: #{n}"
    pixels = bit_buf.unpack('N*')
    puts "First pixel: #{pixels[0].to_s(16)}"
    puts "Second pixel: #{pixels[1].to_s(16)}"
    index = width * (height - 1) + 1
    puts "pixel[#{index}]: #{pixels[index].to_s(16)}"

    puts 'get_pixel:'
    puts get_pixel(x_screen +1, y_screen).to_s(16)
    

    DeleteDC.call(hdcMem)
    DeleteObject.call(hbmp)

  end

end
