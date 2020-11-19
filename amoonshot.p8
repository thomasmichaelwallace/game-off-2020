pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--another moonshot
--@thomasmichaelwallace

function _init()
 printh("_init")
end

function _update60()
 _update_map()
 if(dg.v)then
  _update_dia() 
 else
  _update_fig() 
 end
end

function _draw()
 cls()
 _draw_map()
 _draw_fig()
 _draw_dia()
end
-->8
--map system

mp={--map state
 n=0,--5,--map no.
 x=0,--screen top-left x
 y=0,-- /y
 s={--scroll
  t=false,--scrolling
  n=0,--next map no.
  d=0,--direciton 0⬅️➡️⬆️⬇️3
  x=0,--n/map s/top-left x
  y=0,-- /y
 },
 a={--animations
  t=0,--tick
  f=0,--frame no.
  b=false,--blit.
 }
}

--n:sprite tile no
--sx/y:screen x/y
function mapn(n,sx,sy)
 local y=0
 if(n>7)then
  y=16
  n-=8
 end
 local x=16*n 
 map(x,y,sx,sy,16,16)
 --blit animation
 if(mp.a.b)then
  for ax=x,x+16,1 do
   for ay=y,y+16,1 do
    local m=mget(ax,ay)
    if(m>=128 and m<=191)then
     if(m%2==1)then
      mset(ax,ay,m-1)
     else
      mset(ax,ay,m+1)
     end
    end
   end
  end
  mp.a.b=false
 end
end

function scroll_map()
 local s=8--speed
 if(mp.s.t)then
  if(mp.s.d==1)then
   mp.x-=s
   mp.s.x-=s
   fg.x-=s
   if(mp.s.x<=0)mp.s.t=false
  elseif(mp.s.d==0)then
   mp.x+=s
   mp.s.x+=s
   fg.x+=s
   if(mp.s.x>=0)mp.s.t=false
  elseif(mp.s.d==3)then
   mp.y-=s
   mp.s.y-=s
   fg.y-=s
   if(mp.s.y<=0)mp.s.t=false
  elseif(mp.s.d==2)then
   mp.y+=s
   mp.s.y+=s
   fg.y+=s
   if(mp.s.y>=0)mp.s.t=false
  end
  if(mp.s.t==false)then
   mp.x=0
   mp.y=0
   mp.n=mp.s.n
   mp.s.x=0
   mp.s.y=0
  end
 end
end

--d:scroll direction 0⬅️➡️⬆️⬇️3
function move_map(d)
 local n=mp.n
 if(d==0)then--⬅️
  if(n==0)return
  if(n>4 and n<=8)return
  if(n>12)return
  mp.s.n=n-1
  mp.s.x=-128
 elseif(d==1)then--➡️
  if(n>=4 and n<8)return
  if(n>=12)return
  mp.s.n=n+1
  mp.s.x=128
 elseif(d==2)then--⬆️
  if(n==15)n=16
  if(n==6)n=18
  if(n<=1)return
  if(n==2)n=15
  if(n==3)return
  if(n==4)n=21
  if(n==7 or n==5)return
  mp.s.n=n-8
  mp.s.y=-128
 elseif(d==3)then--⬇️
  if(n==7)n=-6
  if(n==13)n=-4
  if(n==8)n=7
  if(n==9)return
  if(n==10)n=-2
  if(n==11 or n==12)return
  if(n==15 or n==14)return
  mp.s.n=n+8  
  mp.s.y=128
 end
 mp.s.t=true
 mp.s.d=d
end

--x/y:screen x/y
function mgetp(x,y)
 local mx,my=x/8,y/8
 local n=mp.n
 if(n>7)then
  n-=8
  my+=16
 end
 mx+=16*n
 return mget(mx,my)
end

--x/y:screen x/y
--v:map value
function msetp(x,y,v)
 local mx,my=x/8,y/8
 local n=mp.n 
 if(n>7)then
  n-=8
  my+=16
 end
 mx+=16*n
 --syncronise v with ani.
 if(v>=128 and v<=191)v+=mp.a.f
 return mset(mx,my,v)
end

function _update_map()
 --animations
 mp.a.t+=1
 if(mp.a.t==24)then--frames/second
  mp.a.t=0
  mp.a.f=(mp.a.f+1)%2
  mp.a.b=true
 end
 --scroll 
 if(mp.s.t)scroll_map()
end

function _draw_map()
 mapn(mp.n,mp.x,mp.y)
 if(mp.s.t)then
  mapn(mp.s.n,mp.s.x,mp.s.y)
 end
end
-->8
--dialogue system

dg={--dialogue state
 v=false,--show
 n="name",--name
 t="text.",--text
 s=64,--t/l sprite no.
 i=1,--selected index
 c=7,--text color
 h=6,--highlight colour
 o={{--dia.options list
  t="ok",--text
  f=function()end,--selected fn.
 }}
}

ch={--character definitions
 {
 	s=64,--sprite
 	n="rosey lady",--name
 	c=8,--highlight colour
 },
 {s=66,c=14,n="bobby davro"}
}

--n:t/l sprite no.
--w/h:width/height in sprites
--dx/dy:t/l screen position
--s:scale factor
function zspr(n,w,h,dx,dy,s)
 sx,sy=(n%16)*8,(n\16)*8
 sw,sh=8*w,8*h
 dw,dh=sw*s,sh*s
 sspr(sx,sy,sw,sh,dx,dy,dw,dh)
end

--s:string
--lw:max pixel line width
function word_wrap(s,lw)
 local l={}--lines
 local b=""--buffer
 local w=0--line width
 local cl=""--current line
 local cw=0--current width
 local nl=false--new line
 
 for n=1,#s do
  nl=false
  local c=sub(s,n,n)
  if(ord(c)==32)then
   cl,cw=cl..b,w
   b=c
  elseif(ord(c)==10)then
   cl,cw=cl..b,w
   b=""
   nl=true
  else
   b=b..c
  end
  w+=4
  if(ord(c)>127)w+=4
  if(w>lw or nl)then
   if(#cl==0)then
    cl,cw=b,w
    w+=4
    b=" "
   end
   add(l,{t=cl,w=cw})
   cl=""
   b=sub(b,2)
   w-=(cw+4)
  end
 end
 cl=cl..b
 add(l,{t=cl,w=w})
 return l
end

--t:text
--x/y0/1:corners
--h/v:-101 l/c/r h/v align
--c:colour
function text_rect(t,x0,y0,x1,y1,h,v,c)
 local rw=abs(x0-x1)
 local rh=abs(y0-y1)
 local ox=min(x0,x1)
 local oy=min(y0,y1)
 local lns=word_wrap(t,rw)
 for n=1,#lns do
  local l=lns[n]
  local x=ox
  if(h==0)x+=flr((rw-l.w)/2)+1
  if(h==1)x+=(rw-l.w)+2
  if(v==-1)y=6*(n-1)
  if(v==0)y=flr((rh-6*#lns)/2)+6*(n-1)+1
  if(v==1)y=rh-(6*(#lns-n+1))+2
  y+=oy
  print(l.t,x,y,c)
 end
end

--i:tx data index
function show_dia(i)
 local t=tx[i]
 dg.t=t.t
 dg.n=ch[t.c].n
 dg.h=ch[t.c].c
 dg.o=t.o
 dg.v=true
end

function try_dia()
 local c=fig_cast(4,1)
 if(c==nil)return false
 show_dia(c.m)
 return true
end

function _update_dia()
 if(not dg.v)return
 if(btnp(2)and dg.i>1)dg.i-=1
 if(btnp(3)and dg.i<#dg.o)dg.i+=1
 if(btnp(4)or btnp(5))then
  dg.v=false
  dg.o[dg.i].f()
 end
end

function _draw_dia()
 if(not dg.v)return
 --frame
 rectfill(11,11,117,117,0)
 rect(12,12,116,116,dg.h)
 rect(14,14,114,114,dg.h)
 --portrait and header
 zspr(dg.s,2,2,2,2,2)
 print(dg.n,36,24,dg.h)
 --body
 text_rect(dg.t,17,36,110,111,-1,-1,dg.c)
 --options
 print("\n")
 for i=1,#dg.o,1 do
  if(i==dg.i)then
   color(dg.h)
   print("웃"..dg.o[i].t)
  else
   color(dg.c)
   print("  "..dg.o[i].t)
  end
 end
end
-->8
--figure system

fg={--figure state
 x=59,--screen x
 y=59,--/y
 a={--animation sprites
	 --⬅️➡️⬆️⬇️
	 -- - still-move-flip?
	 {{193,209},{209,208},false},
	 {{193,209},{209,208}, true},
	 {{224,240},{194,210},false},
	 {{225,241},{226,242},false},
 },
 d=4,--direction no: 1⬅️➡️⬆️⬇️4
 m=false,--moving?
 t=0,--tick
 f=1,--animation frame no (1/2)
}

--l:length in dir to check
--f:flag to check for
function fig_cast(l,f)
 --fig t/l
 local h=7--sprite height
 local w=6--/width
 --checkpoints 0,1
 local x0=fg.x+(8-w)/2
 local y0=fg.y+(8-h)
 local x1,y1=x0,y0 
 if(fg.d==1)then--⬅️
  x0-=l
  x1,y1=x0,y0+h-1--:웃
 elseif(fg.d==2)then--➡️
  x0+=w+l-1
  x1,y1=x0,y0+h-1--웃:
 elseif(fg.d==3)then--⬆️
  y0-=l          --..
  x1,y1=x0+w-1,y0--웃
 elseif(fg.d==4)then--⬇️
  y0+=h+l-1      --웃
  x1,y1=x0+w-1,y0--''
 end
 local m0,m1=mgetp(x0,y0),mgetp(x1,y1)
 local c=nil
 if(fget(m0,f))then
  c={m=m0,x=x0,y=y0}
 elseif(fget(m1,f))then
  c={m=m1,x=x1,y=y1}
 else
  return nil  
 end
 --normalise anis.
 if(c.m>=128 and c.m<=191)c.m-=c.m%2
 return c
end

function move_fig()
 local s=1/3--speed
 local m=fig_cast(s,0)
 if(m)return false
 if(fg.d==1)fg.x-=s
 if(fg.d==2)fg.x+=s
 if(fg.d==3)fg.y-=s
 if(fg.d==4)fg.y+=s
 return true
end

function _update_fig()
 if(mp.s.t)return--scrolling
 --control
 local m=true
 if(btn(0))then
  fg.d=1
 elseif(btn(1))then
  fg.d=2
 elseif(btn(2))then
  fg.d=3
 elseif(btn(3))then
  fg.d=4
 else
  m=false
 end
 --collide
 if(m)then
  try_push()
  m=move_fig()
 end
 --scroll
 if(fg.x<-4)then
  move_map(0)
 elseif(fg.x>124)then
  move_map(1)
 elseif(fg.y<-4)then
  move_map(2)
 elseif(fg.y>124)then
  move_map(3)
 end
 --interact
 if(btnp(4)or btnp(5))then
  if(try_dia())then
   --sideeffects
  elseif(try_place())then
  elseif(try_cut())then
  end
 end
 --ticker
 fg.t+=1
 if(m~=fg.m)then
  fg.m=m
  fg.t=0--restart
 end
 if(fg.t==24)then
  fg.t=0
  fg.f+=1
  if(fg.f==3)fg.f=1
 end
end

function _draw_fig()
 local a=fg.a[fg.d]
 local m=fg.m and 2 or 1
 local s=a[m][fg.f]
 spr(s,fg.x,fg.y,1,1,a[3])
end
-->8
--text resources

tc={--text constants
 ok={t="ok",f=function()end},
}

tx={--text resources
 [0]={--sprite no.
  c=1,--ch index
  t="test",--text block
  o={{--options list
   t="ok",--text
   f=function()end--sel.function
  }}
 },
 [144]={
  c=1,
  t="oh hai.\nthis is just test.",
  o={tc.ok}
 }
}
-->8
--placable behaviour

pl={--placeble state mechanic
 n=0,--plates held
 s=196,--plate sprite
 r=128,--non-plate sprite
}

function try_place()
 c=fig_cast(8,2)
 if(c==nil)return false
 if(c.m==pl.s)then--pick up
  msetp(c.x,c.y,pl.r)
  pl.n+=1
 elseif(pl.n>0)then--put down
  pl.n-=1
  msetp(c.x,c.y,pl.s)
 end
 return true
end
-->8
--pushable behaviour

pu={
 s=197,--normal sprite
 p=195,--placed sprite
}

function try_push()
 local c=fig_cast(1,3)
 if(c==nil)return
 local x,y=c.x,c.y
 if(fg.d==1)x-=8
 if(fg.d==2)x+=8
 if(fg.d==3)y-=8
 if(fg.d==4)y+=8
 --blocked
 if(fget(mgetp(x,y),0))return
 local m=pu.s
 --placed 
 if(fget(mgetp(x,y),2))m=pu.p
 msetp(c.x,c.y,c.m+1) 
 msetp(x,y,m)
end
-->8
--cut grass behaviour

sw={
 s=211,--cut sprite
}

function try_cut()
 printh("cut!")
 local c=fig_cast(8,4)
 if(c==nil)return false
 msetp(c.x,c.y,c.m+2)
 return true
end
__gfx__
000000002888888249999994faaaaaaf3bbbbbb31cccccc1deeeeeed566666650777777000000000000000000000000000000000000000000000000000000000
000000008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
007007008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
000770008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
000770008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
007007008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
000000008888888899999999aaaaaaaabbbbbbbbcccccccceeeeeeee666666667777777700000000000000000000000000000000000000000000000000000000
000000002888888249999994faaaaaaf3bbbbbb31cccccc1deeeeeed566666650777777000000000000000000000000000000000000000000000000000000000
000000008222222894444449affffffab333333bc111111cedddddde655555560707007000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555557070007700000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555550700070000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555557000700000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555550007000700000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555550070007000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333311111111dddddddd555555557700070700000000000000000000000000000000000000000000000000000000
000000008222222894444449affffffab333333bc111111cedddddde655555560700707000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00008888888800000000aaaaaaaa0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0008888888888000000aaaaaaaaaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
008888888888880000aaaaaaaaaaaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08888888888ffff00aaaaaaaaaa44440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
088888ff8ffffff00aaaaa44a4444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88888fffffffffffaaaaa44444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888ff77ff57ffffaaaa447744574444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8888ff77ff77ffffaaaa447744774444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
888fff75ff77ffffaaa4447544774444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88fffffffff8ffffaa44444444484444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88ffffffff88ffffaa44444444884444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88ffffff888fffffaa44444488844444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88ffff888ffffff0aa44448884444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
88ffffffffffff00aa44444444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
880ffffffffff000aa04444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8800fffffff00000aa00444444400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccc777c11111cc13000300b000300b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cc111177cccccccc30b03b0b0b03b003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
111cc111ccccc77730b03b0b3b003b0b300aa00b300aa00b00000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc7cc1111700b30b0300300b3000a9aa0000ba9b0000000000000000000000000000000000000000000000000000000000000000000000000000000000
ccc777cc1111cc11b00300b300030b0b00aaaa00000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
c111177cccccccccb303b3b3300b3003000aa003000aa00300000000000000000000000000000000000000000000000000000000000000000000000000000000
11cc11117ccccc77b300b3b0b30033b0b00000b0b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc77cc11110300b3000300b3000300b3000300b30000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f000f000f000f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999900099999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09595900095959000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
099f9900099f99000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09998900099899000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09999900099999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900090009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000cf55533ccffffffc0055533000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f00f0000f00f00f555355fff4444ff0555355006000060000000000000000000000000000000000000000000000000000000000000000000000000
000000000044440000444400f566635ff444444f0566635000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000545440000444400f555553ff44ff44f0555553000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000084440000444400f555535ff44ff44f0555535000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ff44f0004f4400f566365ff444444f0566365000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000044440000444440f555535fff4444ff0555535006000060000000000000000000000000000000000000000000000000000000000000000000000000
000000000040040000400000c555553ccffffffc0555553000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f00f0000f00f0000f00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044440000444400004444003000300b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05454400054544000044440000b00b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00844400008444f00044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff44f000ff44400044f40000030003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
044444000044440004444400b00000b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000400000400400000004000300b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000f0000f0000000f00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f444400004444f00044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004554000045540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000044840000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044f400004ff400004ff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400400004004000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f0000000000f0000f00f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700700
004444f00f4444000044440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000700700
00444400004554000045540000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004484000048440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
004f4400004ff400004ff40000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070000007
00444400004444000044444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077000077
00400400004004000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007777770
__gff__
0001010101010101010000000000000000010101010101010100000000000000040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505101020200000000000000000000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009040900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0101010101010101010101010101010102020202020202020202020202020202030000000000030000030000000000030404040404040404040404040404040405000000000005000005000000000005060606060606060606060606060606060700000000000700000700000000000708080808080808080808080808080808
0101000000000000000000000000010000020000000000000000000000000200000300000000000000000000000003000004000000000000000000000000040000050000000000000000000000000505060600000000000000000000000006060707000000000000000000000000070708080000000000000000000000000808
0100000000000101010100000000000000000000000002020202000000000000000000000000000000000000000000000000000000000404040400000000000000000000000000000000000000000005060000000000060606060000000000060700000000000000000000000000000708000000000008080808000000000008
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100010000000000000000000000000102000000000002028000000000000002030000000000000303000000000000030400000000000404040000000000000405000000000000050000000000050005060006000000000606000000000600060700070000000007000000000007000708000800000008080800000000080008
0100010000010000000001000000000000000000000080028000000000000000000000000000000003000000000000000000000000000000040000000000000000000000000000050005000000050005060006000000000600000000000600060700070000000007070700000007000708000800000000000800000000080008
010001000001c500000001000000000000000000000080028000000000000000000000000000000300000000000000000000000000000004040000000000000000000000000000050505000000050005060006000000000006000000000600060700070000000007000700000007000708000800000000000800000000080008
0100010000000000000000000000000102000000000002020200000000000002030000000000000303000000000000030400000000000404040000000000000405000000000000000005000000050005060006000000000606000000000600060700070000000007070700000007000708000800000000000800000000080008
018080808080c4010100009100c5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100000000000080000082828200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0100000000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708000000000000000000000000000008
0101000000000080000000000000010000020000000000000000000000000200000300000000000000000000000003000004000000000000000000000000040000050000000000000000000000000505060600000000000000000000000006060707000000000000000000000000070708080000000000000000000000000808
0100000000000100000100000000000102000000000002000002000000000002030000000000030000030000000000030400000000000400000400000000000405000000000005000005000000000005060000000000060000060000000000060700000000000700000700000000000708000000000008000008000000000008
1100000000001100001100000000001112000000000012000012000000000012130000000000130000130000000000131400000000001400001400000000001415000000000015000015000000000015160000000000160000160000000000161700000000001700001700000000001718000000000018000018000000000018
1111000000000000000000000000110000120000000000000000000000001200001300000000000000000000000013000014000000000000000000000000140000150000000000000000000000001515161600000000000000000000000016161717000000000000000000000000171718180000000000000000000000001818
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100110000000011110000000000001112000000000012121200000000000012130000000000130013130000000000131400000000001400140000000000001415000000000015001515000000150015160016000000160016160000001600161700170000001700170000000017001718001800000018001818000000180018
1100110000001100001100000000000000000000000012001200000000000000000000000000130013130000000000000000000000001400140000000000000000000000000015000015000000150015160016000000160000160000001600161700170000001700171700000017001718001800000018001800000000180018
1100110000000011110000000000000000000000000012121200000000000000000000000000130013130000000000000000000000001400140000000000000000000000000015001500000000150015160016000000160016160000001600161700170000001700171700000017001718001800000018000018000000180018
1100110000001111111100000000001112000000000000001200000000000012130000000000130013130000000000131400000000001400140000000000001415000000000015001515000000150015160016000000160016160000001600161700170000001700001700000017001718001800000018001818000000180018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000012121212000000000000000000000000000000000000000000000000000000001414141400000000000000000000000015151515000000000015160000000000000000000000000000161700000000001717171700000000001718000000000018181818000000000018
1111000000000000000000000000110000120000000000000000000000001200001300000000000000000000000013000014000000000000000000000000140000150000000000000000000000001515161600000000000000000000000016161717000000000000000000000000171718180000000000000000000000001818
1100000000001100001100000000001112121212121212121212121212121212130000000000130000130000000000131414141414141414141414141414141415151515151515151515151515151515160000000000160000160000000000161717171717171717171717171717171718181818181818181818181818181818
