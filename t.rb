# Setup:
# - Camera F7
# - Face North as closely as you can.
# - Zoom all the way in, then back out 4 clicks.
# Good luck!

def apiary
  pb_subimage = PixelBlock.load_image('images/apiary-f8-zoom4.png')
  sleep 0.8  # Wait for running to stop.
  height = screen_size.height
  quarter_height = height / 4

  width = screen_size.width
  quarter_width = width / 4
  search_rect = Rectangle.new(quarter_width, quarter_width, quarter_width * 2, quarter_height * 2)
  pt = find_template_best pb_subimage, 25, search_rect
  
  stat_wait :spd
  if pt
    mm pt
    sleep 0.01
    send_string 't', 0.2
    send_string 'c'
  end
  pw = PopupWindow.find
  pw.dismiss if pw
end

def stash
  return    # XXX Turn stashing off.
  sleep 0.3
  win = find_and_pin 'Warehouse'
  if win
    HowMuch.max if win.click_on 'Stash/Honey'
    HowMuch.max if win.click_on 'Stash/Beeswax'
    win.unpin
  else
    puts "Didn't find warehouse."
  end
end

