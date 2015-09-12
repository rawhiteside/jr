System requirements.

This hasn't been ported much, so the main requirement is probably, "Be
exactly like Bob's box."

-- Ruby
You'll need Ruby.  I've got 1.8.6, but 1.8.7 is probably OK, too.  Do
not get a 1.9.x version.  There were language changes in 1.9, and I've
never tried it, nor do I know what said changes were.  

Get Ruby at http://rubyforge.org/frs/?group_id=167&release_id=42563

-- FxRuby
I'm pretty sure that this comes with the base installer above. 

-- Screen
I've not been careful about screen resolution and desktop themes:
there are lots of absolute coordinates in there.  I run XP at
1024x768, and you'll almost certainly have to run at that resolution.
Further the title bar I have is such that the first pixel ATITD gets
for its viewport is at y=26.  You'll probable need to do this, too.

If you're running Vista, things are even more complicated.  You CANNOT
run this with any of the desktop theme thingies that use Aero, or
whatever it is.  The time necessary for get_pixel is orders of
magnitude slower.  You'll have to choose one of those "classic"
themes, and things can work OK.  

-- Running the macros.
To run this, fire up a DOS prompt, and "cd" to wherever you unpacked
the files.  Type:

    ruby main.rb

If all goes well, a dialog box full of things with checkboxes
appears.  You choose which macros you want to run by checking them.

The NUMLOCK key controls whether the selected macros are paused or
not.  If the light's on, they're running.  You can pause and resume by
pressing NUMLOCK.  Note that this is just pause/resume.  To *restart*
a macro, you've got to uncheck and recheck the box.

I've not documented setup for these, though I've been intending to.
For Cabbages, the set up is:

 - Plant pinned in upper left corner. 
 - F8F8, zoomed all the way in.
 - Standing on a compound floor -- Finding green cabbages on gren
   grass was too hard for me to sort out.  At the "Cabbage Spot" I
   used, there is (or at least used to be) a compound that I used.
   There's a WB there, too
 - Select the Cabbage macro, give ATITD the focus, and press NUMLOCK. 
