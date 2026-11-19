#include <windows.h>
#include <stdio.h>
int main(int c,char**v){ HWND h=(HWND)(ULONG_PTR)strtoull(v[1],0,16);
 int pts[][2]={{900,60},{1300,60},{40,60},{800,1105},{1703,600},{6,600},{1703,1105}};
 for(int i=0;i<7;i++){ LRESULT r=SendMessageA(h,WM_NCHITTEST,0,MAKELPARAM(pts[i][0],pts[i][1])); printf("%d,%d hit=%ld\n",pts[i][0],pts[i][1],(long)r);} 
 RECT wr,cr; GetWindowRect(h,&wr); GetClientRect(h,&cr); printf("win %ld,%ld-%ld,%ld client %ldx%ld zoomed=%d\n",wr.left,wr.top,wr.right,wr.bottom,cr.right,cr.bottom,IsZoomed(h)); return 0; }
