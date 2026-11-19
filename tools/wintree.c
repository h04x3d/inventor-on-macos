#include <windows.h>
#include <stdio.h>
static int depth;
BOOL CALLBACK cb(HWND h, LPARAM l){
  char t[128]="",c[128]=""; RECT r; DWORD pid; GetWindowTextA(h,t,128); GetClassNameA(h,c,128); GetWindowRect(h,&r); GetWindowThreadProcessId(h,&pid);
  if(GetParent(h)!=(HWND)l && l) return TRUE;
  printf("%*s%p pid=%lu vis=%d %ldx%ld@%ld,%ld st=%lx ex=%lx [%s] {%s}\n",depth*2,"",h,pid,IsWindowVisible(h),r.right-r.left,r.bottom-r.top,r.left,r.top,GetWindowLongA(h,GWL_STYLE),GetWindowLongA(h,GWL_EXSTYLE),c,t);
  depth++; EnumChildWindows(h,cb,(LPARAM)h); depth--; return TRUE; }
int main(int c,char**v){ HWND h=(HWND)(ULONG_PTR)strtoull(v[1],0,16); cb(h,0); return 0; }
