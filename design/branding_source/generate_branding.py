from PIL import Image
import numpy as np
# Regenerates assets/branding/* from the two master files in this folder.
# Run from the project root: python design/branding_source/generate_branding.py
A='design/branding_source/'; O='assets/branding/'
m=Image.open(A+'vellora_mark_master.png').convert('RGBA')
a=np.array(m)
alpha=a[...,3]
ys,xs=np.where(alpha>200)
x0,x1,y0,y1=xs.min(),xs.max()+1,ys.min(),ys.max()+1
print('tile bbox',x0,x1,y0,y1)
tile=m.crop((x0,y0,x1,y1))
side=max(tile.size)
sq=Image.new('RGBA',(side,side),(0,0,0,0)); sq.paste(tile,((side-tile.width)//2,(side-tile.height)//2))
mark=sq.resize((1024,1024),Image.LANCZOS)
mark.resize((512,512),Image.LANCZOS).save(O+'vellora_mark.png',optimize=True)
t=np.array(mark).astype(float)
# gold V mask
R,G,B=t[...,0],t[...,1],t[...,2]
score=np.clip((R-B-8)/45,0,1)*np.clip((R-45)/40,0,1)*(t[...,3]/255)
v=np.zeros_like(t); v[...,:3]=t[...,:3]; v[...,3]=score*255
vimg=Image.fromarray(v.astype('uint8'),'RGBA')
ys_,xs_=np.where(v[...,3]>60); bb=(xs_.min(),ys_.min(),xs_.max()+1,ys_.max()+1); print('V bbox',bb)
vcrop=vimg.crop(bb)
def place(img,width,canvas=1024,dy=0):
    w=width; h=round(img.height*w/img.width)
    r=img.resize((w,h),Image.LANCZOS)
    c=Image.new('RGBA',(canvas,canvas),(0,0,0,0))
    c.paste(r,((canvas-w)//2,(canvas-h)//2+dy),r); return c
place(vcrop,735).save(O+'vellora_icon_foreground.png',optimize=True)
# background gradient sampled from tile
def samp(px,py):
    return t[int(py*1024),int(px*1024),:3]
tl,tr,bl,br=samp(.2,.2),samp(.8,.2),samp(.2,.8),samp(.8,.8)
print(tl,tr,bl,br)
u=np.linspace(0,1,1024)[None,:,None]; vv=np.linspace(0,1,1024)[:,None,None]
bg=(tl*(1-u)*(1-vv)+tr*u*(1-vv)+bl*(1-u)*vv+br*u*vv)
bgimg=Image.fromarray(bg.astype('uint8'),'RGB')
bgimg.save(O+'vellora_icon_background.png',optimize=True)
icon=bgimg.convert('RGBA'); fg=place(vcrop,610,dy=0); icon.alpha_composite(fg)
icon.convert('RGB').save(O+'vellora_icon.png',optimize=True)
# horizontal
h=Image.open(A+'vellora_logo_horizontal_master.png').convert('RGBA'); ha=np.array(h)
ys,xs=np.where(ha[...,3]>40); print('h bbox',xs.min(),xs.max(),ys.min(),ys.max())
hb=h.crop((xs.min()-6,ys.min()-6,xs.max()+7,ys.max()+7))
# wordmark region: columns right of x=610 in original coords
wm=h.crop((600,350,1640,620)); wa=np.array(wm); ys2,xs2=np.where(wa[...,3]>40)
wm=wm.crop((xs2.min(),ys2.min(),xs2.max()+1,ys2.max()+1))
w=np.array(wm); white=w.copy(); white[...,:3]=255
wl=Image.fromarray(white,'RGBA')
wl.resize((800,round(wl.height*800/wl.width)),Image.LANCZOS).save(O+'vellora_wordmark_light.png',optimize=True)
hb.resize((1200,round(hb.height*1200/hb.width)),Image.LANCZOS).save(O+'vellora_logo.png',optimize=True)
# dark horizontal: gold V + white wordmark
vh=int(wm.height*1.9); vw=round(vcrop.width*vh/vcrop.height)
vr=vcrop.resize((vw,vh),Image.LANCZOS)
gap=int(wm.height*0.32)
W=vw+gap+wm.width; H=max(vh,wm.height)
c=Image.new('RGBA',(W,H),(0,0,0,0)); c.paste(vr,(0,(H-vh)//2),vr); c.paste(wl,(vw+gap,(H-wm.height)//2+int(wm.height*0.2)),wl)
c.resize((1200,round(H*1200/W)),Image.LANCZOS).save(O+'vellora_logo_dark.png',optimize=True)
print(wm.size)
