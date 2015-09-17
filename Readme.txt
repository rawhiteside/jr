System requirements.

This hasn't been ported much, so the main requirement is probably, "Be
exactly like Bob's box."

-- Running the macros.
To run this, fire up a DOS prompt, and "cd" to wherever you unpacked
the files.  Type:

    runj

It runs in a cygwin term as well. 

If all goes well, a dialog box full of things with checkboxes
appears.  You choose which macros you want to run by checking them.

ATITD has to be full-screen.  That's how I run it, and therefore was
sloppy about getting window/screen sizes.

The NUMLOCK key controls whether the selected macros are paused or
not.  If the light's on, they're running.  You can pause and resume by
pressing NUMLOCK.  Note that this is just pause/resume.  To *restart*
a macro, you've got to uncheck and recheck the box.

It's java, but it won't run on a *nix.  It mades a Win32 call in
exactly one place:  the thread that monitors the NUMLOCK status.
There's an ancient Java bug such that getLockingKeyState is
borken. Nobody votes to fix it. 

It's quite multi-threaded, but unless you want to write an Action that
creates its own threads, you shouldn't have to worry about it.  All
the locking stuff is handled at a low level.  Even then, it's probably
OK, as long as you use ControllableThread.


