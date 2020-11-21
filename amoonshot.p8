pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
--another moonshot
--@thomasmichaelwallace

--flags:
--0:blocks char
--   unless 4,4 is trans and map
--    has colour changer.
--   blocks looker sight unless
--    is in lk.t
--1:can be talked to
--   looks up tx[v] for dia.
--2:can host/is placeable
--   (+1) is host else placable
--3:can be pushed/pushed on
--   (+1) is pushable else on.
--4:can be cut
--5:can be collected
--6:is colour changer
--7:is swing hook

function _init()
 printh("_init")
end

function _update60()
 _update_map()
 if(dg.v)then
  _update_dia()
 else
  _update_lok()
  _update_fig()
  _update_cut()
  _update_swg()
 end
end

function _draw()
 cls()
 _draw_map()
 _draw_lok()
 _draw_fig()
 _draw_dia()
 _draw_cut()
end
-->8
--map system

mp={--map state
 n=12,--5,--map no.
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
 if(rb.c~=nil)palt(rb.c,true)
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
 if(rb.c~=nil)palt(rb.c,false)
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
 local sx,sy=(n%16)*8,(n\16)*8
 local sw,sh=8*w,8*h
 local dw,dh=sw*s,sh*s
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

--i:tx data index/{cto}object
function show_dia(i)
 local t=type(i)=="table"and i or tx[i]
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
 x=112,y=8,--screen x/y
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

--m:map tile no
--f:flag to check for
function fpget(m,f)
 local b=fget(m,f)
 if(not b)return false
 if(f>0)return true
 if(rb.c==nil)return true
 local x,y=(m%16)*8+4,(m\16)*8+4
 local c=sget(x,y)
 return c~=rb.c
end

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
 if(fpget(m0,f))then
  c={m=m0,x=x0,y=y0}
 elseif(fpget(m1,f))then
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
 if(hk.t)return--swinging
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
  try_collect()
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
  elseif(try_col())then
  elseif(try_swing())then
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
 else
  return false
 end
 return true
end
-->8
--pushable behaviour

pu={
 s=197,--normal sprite
 p=195,--placed sprite
 e=0,--effort
 x=0,--effort application x
 y=0,--/y
}

function try_push()
 local c=fig_cast(1,3)
 if(c==nil)return false
 --only push blocks
 if(not fget(c.m,0))return false
 --expend effort
 if(c.x==pu.x and c.y==pu.y)then
  pu.e+=1
 else
  pu.e,pu.x,pu.y=1,c.x,c.y
 end
 if(pu.e<16)return false
 --do push
 local x,y=c.x,c.y
 if(fg.d==1)x-=8
 if(fg.d==2)x+=8
 if(fg.d==3)y-=8
 if(fg.d==4)y+=8
 --blocked
 local t=mgetp(x,y)
 if(fget(t,0))return false
 if(not fget(t,3))return false
 local m=pu.s
 --placed 
 if(fget(mgetp(x,y),2))m=pu.p
 msetp(c.x,c.y,c.m+1) 
 msetp(x,y,m)
 return true
end
-->8
--cut grass behaviour

sw={
 s=211,--cut sprite
 n=0,--count
 t=false,--cutting
 f=0,--animation frame
 d=0,--/dir 1⬅️➡️⬆️⬇️4
 c=nil,--effected cast
 r=0,--animation rater
}

function try_collect()
 local x,y=fg.x+4,fg.y+4
 local m=mgetp(x,y)
 if(not fget(m,5))return false
 msetp(x,y,sw.s)
 sw.n+=1
 return true
end

function try_cut()
 --wait for animation
 if(sw.t)return false
 --trigger animation
 sw.t,sw.f,sw.d=true,0,fg.d
 --test effect 
 sw.c=fig_cast(8,4) 
 return c~=nil
end

function _update_cut()
 if(not sw.t)return
 sw.r+=1
 if(sw.f==0)sw.r=4--first timer
 if(sw.r==4)then
  sw.f+=1--move frame
  sw.r=0
 end
 if(sw.f==2 and sw.c)then
  msetp(sw.c.x,sw.c.y,sw.c.m+2)
 elseif(sw.f>3)then
  sw.t=false--end anim
 end
end

function _draw_cut()
 if(not sw.t)return
 local x=fg.x+4
 local y=fg.y+4
 local h=false
 local v=false
 if(sw.d==1)then
  x-=6
  y-=1
  h=true
  v=true
 elseif(sw.d==2)then
  x+=6
  y-=1
  v=true
 elseif(sw.d==3)then
  y-=7
  v=true
 elseif(sw.d==4)then
  y+=8
 end
 spr(211+sw.f,x-4,y-4,1,1,h,v)
end
-->8
--rainbow behaviour

rb={
 c=nil
} 

function try_col()
 local c=fig_cast(3,6)
 if(c==nil)return false
 local l=rb.c or 7
 l+=1
 if(l>14)then
  rb.c=nil
 else
  rb.c=l
 end
 return true
end
-->8
--looker beaviour

lk={--looker state
 l={--lookers
  {--screen
   n=2,--screen
   x=39,y=7,--map x/y
   s=243,--first sprite
   v=60,--turn speed
   r=1,--rotate direction
   d=0,--direction 0⬅️⬆️➡️⬇️3
   t=0,--ticker
   h={--dialog c/t/o
    c=1,
    t="get out of here 2!",
    o={tc.ok},
   },
  },
  {
   n=7,x=116,y=9,
   s=243,
   v=60,r=1,
   d=0,t=0,
   h={
    c=1,o={tc.ok},
    t="get out of here 7.1!",
   },
  },
  {
   n=7,x=122,y=3,
   s=243,
   v=60,r=-1,
   d=3,t=0,
   h={
    c=1,o={tc.ok},
    t="get out of here 7.2!",
   },
  }
 },
 u=false,--update
 s=false,--spotted
 t={35,40},--see-thru
}

--l:looker instance
function lok_cast(l)
 local x,y=l.x*8%128+4,l.y*8%128+4
 local dx,dy=0,0--cast delta
 if(l.d==0)dx=-8--⬅️
 if(l.d==1)dy=-8--⬆️
 if(l.d==2)dx=8 --➡️
 if(l.d==3)dy=8 --⬇️
 local h=false--hit
 local s=false--stop
 local cw=6--check width
 local ch=cw--/height
 while(not s)do 
  x+=dx
  y+=dy  
  local cx,cy=x-4-cw,y-4-ch
  --spotted
  if(fg.x>cx and fg.x<(cx+2*cw)
   and fg.y>cy and fg.y<(cy+2*ch))then
   h,s=true,true
  end
  --off edge
  if(x<0 or x>128)s=true
  if(y<0 or y>128)s=true
  --hit block
  local m=mgetp(x,y)
  if(fget(m,0))then
   s=true
   for t in all(lk.t) do
    --unless transparent
    if(m==t)s=false
   end
  end  
 end
 return h
end

function _update_lok() 
 if(mp.s.t)return--skip scroll
 local c=false--clear
 for l in all(lk.l) do
  --don't see across screens
  if(l.n==mp.n)then
   --rotate 
		 l.t+=1
		 if(l.t>l.v)then
		  l.d+=l.r
		  l.t=0
		  if(l.d>3)l.d=0
		  if(l.d<0)l.d=3
		  c=true
		 end
	  --cast
		 if(not lk.s and lok_cast(l))then
		  lk.s=true
		  show_dia(l.h)
		 end
		end
 end
 if(c)lk.s=false
end

function _draw_lok()
 for l in all(lk.l) do
  if(l.n==mp.n)mset(l.x,l.y,l.s+l.d)
 end
end
-->8
--swing behaviour

hk={--hook state
 s=false,--swinging
 dx=0,--dx to move until dest.
 dy=0,--/y
}

function try_swing()
 local c=fig_cast(2,7)
 if(c==nil)return false
 --do swing
 local x,y=c.x,c.y
 local dx,dy=0,0
 if(fg.d==1)dx=-8
 if(fg.d==2)dx=8
 if(fg.d==3)dy=-8
 if(fg.d==4)dy=8
 x+=dx
 y+=dy
 --blocked
 if(fget(mgetp(x,y),0))return false
 hk.s=true
 hk.dx,hk.dy=2*dx,2*dy
 return true
end

function _update_swg()
 if(not hk.s)return
 if(abs(hk.dx)>0)then
  local d=sgn(hk.dx)
  fg.x+=d
  hk.dx-=d
 elseif(abs(hk.dy)>0)then
  local d=sgn(hk.dy)
  fg.y+=d
  hk.dy-=d  
 else
  hk.s=false
 end
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
000000008222222894444449affffffab333333b43333334edddddde655555560707007000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333333bbbb33dddddddd555555557070007700000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff333333333bbbb8b3dddddddd555555550700070000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff333333333bbbbbb3dddddddd555555557000700000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff333333333b8bbbb3dddddddd555555550007000700000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff333333333bbbbbb3dddddddd555555550070007000000000000000000000000000000000000000000000000000000000
000000002222222244444444ffffffff3333333333bb8b33dddddddd555555557700070700000000000000000000000000000000000000000000000000000000
000000008222222894444449affffffab333333b43333334edddddde655555560700707000000000000000000000000000000000000000000000000000000000
000000000222222000000000a0a0a0a0000000000bbbbbb000000000000000007070707000000000000000000000000000000000000000000000000000000000
0000000020202022000000000a0a0a0a00000000bb0000bb00000000000000000707070700000000000000000000000000000000000000000000000000000000
0000000022020202000000000000000000000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000020000002200000020000000000000000b000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000002000000220000002a0a0a0a000000000b000000b00000000000000007070707000000000000000000000000000000000000000000000000000000000
0000000000000000220202020a0a0a0a00000000b000000b00000000000000000707070700000000000000000000000000000000000000000000000000000000
0000000000000000202020220000000000000000bb0000bb00000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000222222000000000000000000bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00007770ccc110013000300b000300b3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001ccc770000000030b03b0b0b03b003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
c1100ccc0000077730b03b0b3b003b0b300aa00b300aa00b00000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007001ccc700b30b0300300b3000a9aa0000ba9b0000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700cc1100ccb00300b300030b0b00aaaa00000aa00000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ccc77000000000b303b3b3300b3003000aa003000aa00300000000000000000000000000000000000000000000000000000000000000000000000000000000
1100cccc70000077b300b3b0b30033b0b00000b0b00000b000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077001ccc0300b3000300b3000300b3000300b30000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
000000000000000000000000c666666cc44ffffc3666666330000303000000000000000000000000000000000000000000000000000000000000000000000000
0000000000f00f0000f00f0066666666440000ff66666666030b0000000000000000000000000000000000000000000000000000000000000000000000000000
000000000044440000444400655555564000000f6555555630003030000000000000000000000000000000000000000000000000000000000000000000000000
00000000054544000044440066666666f004f00f6666666600300300000000000000000000000000000000000000000000000000000000000000000000000000
00000000008444000044440065555556f00f400f6555555603b0003b000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ff44f0004f440066666666f000000466666666b0300300000000000000000000000000000000000000000000000000000000000000000000000000
00000000004444000044444065555556ff0000446555555600300033000000000000000000000000000000000000000000000000000000000000000000000000
00000000004004000040000066666666cffff44c66666666300300b3000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f00f0000f00f0000f00f00000000000a6666600a5050500a000000000000000000000000000000000000000000000000000000000000000000000000000000
0044440000444400004444003000300b000000000060505006000000000000000000000000000000000000000000000000000000000000000000000000000000
05454400054544000044440000b00b00000000000065005006000000000000000000000000000000000000000000000000000000000000000000000000000000
00844400008444f00044440000000000000000000006050006000000000000000000000000000000000000000000000000000000000000000000000000000000
00ff44f000ff44400044f40000030003000000000006550006000000000000000000000000000000000000000000000000000000000000000000000000000000
044444000044440004444400b00000b0000000000000600006000000000000000000000000000000000000000000000000000000000000000000000000000000
0000400000400400000004000300b300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000006655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000f0000f0000000f00f0065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0f444400004444f0004444006559a556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004554000045540055855b55000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000044840055755c55000560000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0044f400004ff400004ff400655ed556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00444400004444000444440065555556000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00400400004004000000040006655660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00f0000000000f0000f00f0000c00c0000c00c0000c00c0000c00c00000000000000000000000000000000000000000000000000000000000000000000700700
004444f00f4444000044440000444400004444000044440000444400000000000000000000000000000000000000000000000000000000000000000000700700
00444400004554000045540005454400004444000044545000455400000000000000000000000000000000000000000000000000000000000000000000000000
00444400004484000048440000844400004444000044480000448400000000000000000000000000000000000000000000000000000000000000000000000000
004f4400004ff400004ff400004444c0004c44000c44440000444400000000000000000000000000000000000000000000000000000000000000000070000007
00444400004444000044444000cccc0000cccc0000cccc0000cccc00000000000000000000000000000000000000000000000000000000000000000077000077
00400400004004000040000000c00c0000c00c0000c00c0000c00c00000000000000000000000000000000000000000000000000000000000000000007777770
__gff__
0001010101010101010000000000000000010101010101010100000000000000040000010000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0505101020200000000000000000000003030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009040908000000000000000000000000000000000000000000000000000000004181000000000000000000000000000001010101000000000000000000
__map__
0101010101010101010101010101010102020202020202020202020202020202030000000000000000000000000000030404040404040404040404040404040405000000000005000005000000000005060606060606060606060606060606060700000000000700000700000000000700000808080808080808000808080808
0101000000000000000000000000010000020000000000000000000000000200030303030303030303030003030303030004000000000000000000000000040000050000000000000000000000000505060600000000000000000000000006060707000000000000000000000000070700000800000000000008000800000008
0100000000000101010100000000000000000000000002020202000000000000030000000000000000000000000000030000000000000404040400000000000000000000000000000000000000000005060000000000060606060000000000060700000000000000000000000000000700000800080808280008080800000008
0100000000000000000000000000000000000000000000000000000000000000030023002323232323232323232323030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000800000000280000f30000000008
0100000000012201010100000000000000000000000000000000000000000000030023000300000000000000000000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000808080800280008000800000008
010000000001e401e40100000000000000000000000000000000000000000000030023000300230003030300000000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000800000000280000000000000808
0100010000012101210100000000000102000000000002028000000000000002030023000300230000000300030000030400000000000404040000000000000405000000000000050000000000050005060006000000000606000000000600060700070000000007000000000007000700000800282828282828282808080800
010001000001000000000100000000000000000000008002800000000000000003002300000023f300000000000000030000000000000000040000000000000000000000000000050005000000050005060006000000000600000000000600060700070000000007070700000007000700000800000808280000002800000800
010001000001c500000001000000000000000000000080028000000000000000032323232323230000000300030000030000000000000004040000000000000000000000000000050505000000050005060006000000000006000000000600060700070000000007000700000007000700000800000008280028002800000800
0100010000000000000000000000000102000000000002020200000000000002030000000000232323000300030000030400000000000404040000000000000405000000000000000005000000050005060006000000000606000000000600060700070000000007070700000007000700000800f30000280028002800000808
018080808080c4010100009100c5000000000000000000000000000000000000030000000000000000000300030000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000800000000000028000000000008
0100000000000080000000000000000000000000000000000000000000000000030303030000000000000300030000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000828282828282828000000000008
0100000000000080000082828200000000000000000000000000000000000000030000030303030003030300030000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000700000800000000000028080808080008
0100000000000080000000000000000000000000000000000000000000000000030000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000005060000000000000000000000000000060700000000000000000000000000000708080800000000000000000000000008
0101000000000080000000000000010000020000000000000000000000000200030000000000030303030303030303030004000000000000000000000000040000050000000000000000000000000505060600000000000000000000000006060707000000000000000000000000070708000000000000000000000000000008
0100000000000100000100000000000102000000000002000002000000000002030000000000000000000000000000030400000000000400000400000000000405000000000005000005000000000005060000000000060000060000000000060700000000000700000700000000000700000000000000000000000000000000
1100000000001100001100000000001112000000000012000012000000000012130000000000130000130000000000131400000000001400001400000000001415151515151515151515151515151515160000000000160000160000000000161700000000001700001700000000001718000000000018000018000000000018
1111000000000000000000000000110000120000000000000000000000001200001300000000000000000000000013000014000000000000000000000000140000000000000000000000000000000015161600000000000000000000000016161717000000000000000000000000171718180000000000000000000000001818
11000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c4000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000252525252515160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
110000000000020101010300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025c6c5c62515160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
110000000000020000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000025c6c6c62515160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100110000000200e3000300000000111200000000001212120000000000001213000000000013001313000000000013140000000000140014000000000000140000000000000000000025c6c6c62515160016000000160016160000001600161700170000001700170000000017001718001800000018001818000000180018
1100110000000200000003000000000000000000000012001200000000000000000000000000130013130000000000000000000000001400140000000000000000000000000000000000252525252515160016000000160000160000001600161700170000001700171700000017001718001800000018001800000000180018
1100110004040400000005050500000000000000000012121200000000000000000000000000130013130000000000000000000000001400140000000000000000000000000000000000000000000015160016000000160016160000001600161700170000001700171700000017001718001800000018000018000000180018
1100110006060606011616161600001112000000000000001200000000000012130000000000130013130000000000131400000000001400140000000000001400000000000000000000000000000015160016000000160016160000001600161700170000001700001700000017001718001800000018001818000000180018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000015160000000000000000000000000000161700000000000000000000000000001718000000000000000000000000000018
1100000000000000000000000000000000000000000012121212000000000000000000000000000000000000000000000000000000001414141400000000000000000000000000000000000000000015160000000000000000000000000000161700000000001717171700000000001718000000000018181818000000000018
1111000000000000000000000000110000120000000000000000000000001200001300000000000000000000000013000014000000000000000000000000140000000000000000000000000000000015161600000000000000000000000016161717000000000000000000000000171718180000000000000000000000001818
1100000000001100001100000000001112121212121212121212121212121212130000000000130000130000000000131414141414141414141414141414141415151515151515151515151515151515160000000000160000160000000000161717171717171717171717171717171718181818181818181818181818181818
