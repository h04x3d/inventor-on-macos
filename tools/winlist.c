#include <windows.h>
#include <stdio.h>
static int mode;
BOOL CALLBACK cb(HWND h, LPARAM l){
  char t[256]="",c[256]=""; RECT r; DWORD pid;
  if(!IsWindowVisible(h)) return TRUE;
  GetWindowTextA(h,t,256); GetClassNameA(h,c,256); GetWindowRect(h,&r);
  GetWindowThreadProcessId(h,&pid);
  LONG ex=GetWindowLongA(h,GWL_EXSTYLE);
  int w=r.right-r.left, ht=r.bottom-r.top;
  if(mode==0) printf("%p pid=%lu %dx%d@%d,%d ex=%lx top=%d [%s] {%s}\n",h,pid,w,ht,r.left,r.top,ex,!!(ex&WS_EX_TOPMOST),c,t);
  return TRUE;
}
int main(int argc,char**argv){
  if(argc>2){ HWND h=(HWND)(ULONG_PTR)strtoull(argv[2],0,16);
    if(!strcmp(argv[1],"front")){ SetWindowPos(h,HWND_TOPMOST,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_SHOWWINDOW); SetForegroundWindow(h); }
    if(!strcmp(argv[1],"untop")) SetWindowPos(h,HWND_NOTOPMOST,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);
    if(!strcmp(argv[1],"bottom")) SetWindowPos(h,HWND_BOTTOM,0,0,0,0,SWP_NOMOVE|SWP_NOSIZE|SWP_NOACTIVATE);
    if(!strcmp(argv[1],"pos")&&argc>6) SetWindowPos(h,0,atoi(argv[3]),atoi(argv[4]),atoi(argv[5]),atoi(argv[6]),SWP_NOZORDER|SWP_NOACTIVATE);
    if(!strcmp(argv[1],"max")) ShowWindow(h,SW_MAXIMIZE);
    if(!strcmp(argv[1],"restore")) ShowWindow(h,SW_RESTORE);
    return 0; }
  EnumWindows(cb,0); return 0; }
