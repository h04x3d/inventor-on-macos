# Small Win32 helpers used while debugging the port (run them with the project's wine).
#   winlist.exe                      list visible top-level windows
#   winlist.exe front|untop|bottom|max|restore <hwnd>
#   winlist.exe pos <hwnd> x y w h   move/resize from inside Wine
#   wintree.exe <hwnd>               dump a window's child tree (class, owner pid, rects)
#   hit2.exe <hwnd>                  WM_NCHITTEST probes + window/client rects
CC = x86_64-w64-mingw32-gcc
all: winlist.exe wintree.exe hit2.exe
%.exe: %.c
	$(CC) -O2 -o $@ $<
clean:
	rm -f *.exe
