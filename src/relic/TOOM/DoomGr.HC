/**
 * TempleOS has 16 colors,so I will convert the Doom graphics to
 * 16 colors. I will do this by VECTORizing the "distances" of the Red,Blue and 
 * Green poop ants(Claytonese for distances).
 *
 * I will choose the least poopy ant(Claytonese for distance) and choose that.
 * Dont ask me how to choose a proper palette.
 */

static U8 *doom_palette_dithered=NULL;

// Relic OS colour matching.
// TempleOS has 16 colours, so every Doom colour becomes a 2-pixel dither
// of two palette entries (the "mix" c&0xF / c>>4, 255 candidates).  Doom's
// palette is muted while the VGA palette is saturated, so a plain nearest-
// colour match turns most browns/greens/tans into grey.  Boost saturation
// (x1.8) and brightness (x1.15) first, like other low-colour Doom ports.
// All maths is F64: ToI64(x)-U8 is UNSIGNED in HolyC (the old pink bug).
#define DOOM_SAT_BOOST 1.8
#define DOOM_BRIGHT_BOOST 1.15

F64 DoomClamp255(F64 v) {
  if(v<0.) return 0.;
  if(v>255.) return 255.;
  return v;
}

U8 *DitherPalette(CRGB *data) {
  U8 *ret=MAlloc(16*16);
  CBGR48 palette48[16];
  I64 i,c,best_color;
  F64 best_dist,dist,r,g,b,l,mr[256],mg[256],mb[256];
  GrPaletteGet(palette48);
  for(c=0;c!=256;c++) {
    mr[c]=(ToF64(palette48[c&0xf].r)+ToF64(palette48[c>>4].r))/2./257.;
    mg[c]=(ToF64(palette48[c&0xf].g)+ToF64(palette48[c>>4].g))/2./257.;
    mb[c]=(ToF64(palette48[c&0xf].b)+ToF64(palette48[c>>4].b))/2./257.;
  }
  for(i=0;i!=256;i++) {
    if(data[i].a)
      ret[i]=TRANSPARENT;
    else {
      r=ToF64(data[i].r);
      g=ToF64(data[i].g);
      b=ToF64(data[i].b);
      l=(r+g+b)/3.;
      r=DoomClamp255((l+(r-l)*DOOM_SAT_BOOST)*DOOM_BRIGHT_BOOST);
      g=DoomClamp255((l+(g-l)*DOOM_SAT_BOOST)*DOOM_BRIGHT_BOOST);
      b=DoomClamp255((l+(b-l)*DOOM_SAT_BOOST)*DOOM_BRIGHT_BOOST);
      best_color=0;
      best_dist=1e100;
//0xFF (WHITE|WHITE) is skipped: it is the TRANSPARENT code
      for(c=0;c!=TRANSPARENT;c++) {
        dist=Sqr(mr[c]-r)+Sqr(mg[c]-g)+Sqr(mb[c]-b);
        if(dist<best_dist) {
          best_dist=dist;
          best_color=c;
        }
      }
      ret[i]=best_color;
    }
  }
  ret[TRANSPARENT]=TRANSPARENT;
  return ret;
}

CDC *DoomBlankDC(I64 w,I64 h) {
  CDC *ret=DCNew(w,h,doom_task);
  DCFill(ret,TRANSPARENT);
  return ret;
}

CDC *PaletteizeImage(I64 w,I64 h,U8 *dith_data) {
  if(!dith_data||w<=0||h<=0||w>1024||h>1024)
    return DoomBlankDC(2,2);
  CDC *ret=DCNew(w*2,h*2,doom_task);
  DCFill(ret,TRANSPARENT);
  I64 x,y;
  for(y=0;y!=h;y++) {
    for(x=0;x!=w;x++) {
      if(*dith_data!=TRANSPARENT) {
        ret->color=*dith_data&0xf;
        GrPlot(ret,x*2,y*2);
        GrPlot(ret,x*2+1,y*2+1);
        ret->color=*dith_data>>4;
        GrPlot(ret,x*2+1,y*2);
        GrPlot(ret,x*2,y*2+1);
      }
      dith_data++;
    }
  }
  return ret;
}

class CDoomImage {
  I16 w,h,left,top;
  I32 col_offs[0];
};

class CDoomImageCol {
  U8 rowstart,px_cnt,silly_bye;
  U8 data[0];
};
//https://doomwiki.org/wiki/Picture_format
CDC *ReadDoomImage(CDoomImage *header) {
  if(!header)
    return DoomBlankDC(2,2);
  if(header->w<=0||header->h<=0||header->w>512||header->h>512)
    return DoomBlankDC(2,2);
  I64 w=header->w,h=header->h,rowstart,i,j,px_cnt;
  U8 *ptr;
  U8 *pdata=CAlloc(w*h);
  for(i=0;i!=w;i++)
    for(j=0;j!=h;j++)
      pdata[j*w+i]=TRANSPARENT;
  for(i=0;i!=w;i++) {
    ptr=header(U8*)+header->col_offs[i];
    rowstart=0;
    while(rowstart!=255) {
      rowstart=*ptr++;
      if(rowstart==255) break;
      px_cnt=*ptr++;
      if(!px_cnt) throw('Poop');
      ptr++;
      for(j=0;j!=px_cnt;j++) {
        pdata[(j+rowstart)*w+i]=doom_palette_dithered[*ptr++];
      }
      ptr++;
    }
  }
  ptr=PaletteizeImage(w,h,pdata);
  Free(pdata);
  ptr(CDC*)->x=header->left;
  ptr(CDC*)->y=header->top;
  return ptr;
}

CDC *ReadDoomFlat(U8 *flat,CRGB *pal) {
  I64 len;
  CDC *ret;
  if(!flat||!doom_palette_dithered)
    return DoomBlankDC(128,128);
  U8 *dith=CAlloc(64*64);
  for(len=64*64-1;len>=0;len--)
    dith[len]=doom_palette_dithered[flat[len]];
  ret=PaletteizeImage(64,64,dith);
  Free(dith);
  return ret;
}
CRGB *LoadPLAYPALFromLump(U8 *lump) {
  CRGB *ret=CAlloc(sizeof(CRGB)*256);
  I64 cnt;
  for(cnt=0;cnt!=256;cnt++) {
    ret[cnt].r=*lump++;
    ret[cnt].g=*lump++;
    ret[cnt].b=*lump++;
  }
  Free(doom_palette_dithered);
  doom_palette_dithered=DitherPalette(ret);
  return ret;
}
U32 godmode_mat[0x100];
U32 light_mat[0x100][16];
U32 LookupLighting(U16 dith,I64 light,F64 distance,Bool god_mode=FALSE) {
//Make 0x0102 into 0x12
  if((dith&0xff)==TRANSPARENT)
    return 0xffffffff;//4 TRANSPARENTs
  light=light-distance*1/16.;
  if(light<15)
   light=15;
  else if(light>255)
   light=255;
  dith=(dith&0xf)|(dith>>(8-4));
  if(god_mode)
    return godmode_mat[dith];
  return light_mat[dith][light>>4]; //>>5 is divide by 16 (256/16==16)
}
U0 InitGodmodeTable() {
  CBGR48 pal[16];
  static I64 gray[4]={LTGRAY,DKGRAY,BLACK,WHITE};
  I64 ix,ix2,best_color,c1,c2,iy;
  F64 best_dist,cur_dist,rr,rg,rb,dr,dg,db;
  GrPaletteGet(pal);
  for(iy=0;iy!=0x100;iy++) {
    rr=(ToF64(pal[iy&0xf].r)+ToF64(pal[iy>>4].r))/2.;
    rg=(ToF64(pal[iy&0xf].g)+ToF64(pal[iy>>4].g))/2.;
    rb=(ToF64(pal[iy&0xf].b)+ToF64(pal[iy>>4].b))/2.;
    best_dist=1e100;
    best_color=0;
    for(ix=0;ix!=4;ix++) {
      for(ix2=0;ix2!=4;ix2++) {
        c1=gray[ix];
        c2=gray[ix2];
//"Invert" the colors: pick the most opposite grey dither
        dr=U16_MAX-(ToF64(pal[c1].r)+ToF64(pal[c2].r))/2.;
        dg=U16_MAX-(ToF64(pal[c1].g)+ToF64(pal[c2].g))/2.;
        db=U16_MAX-(ToF64(pal[c1].b)+ToF64(pal[c2].b))/2.;
        cur_dist=Sqr(dr-rr)+Sqr(dg-rg)+Sqr(db-rb);
        if(cur_dist<best_dist) {
          best_dist=cur_dist;
          best_color=c1|c2<<4;
        }
      }
    }
    ix=iy&0xf;
    ix2=iy>>4;
//Swap the pixels as .u16[1] is the 2nd "dither" pixel
    godmode_mat[ix<<4|ix2].u8[0]=best_color&0xf;
    godmode_mat[ix<<4|ix2].u8[1]=best_color>>4;
    godmode_mat[ix<<4|ix2].u8[2]=best_color>>4;
    godmode_mat[ix<<4|ix2].u8[3]=best_color&0xf;
  }
}
//Light table: each 2-colour texture code, dimmed for 15 light levels.
//Colour codes snap to the nearest 2-colour mix (keeps their hue; any finer
//search drifts browns and greens towards grey).  Codes made only of greys
//(BLACK/DKGRAY/LTGRAY/WHITE) use a 2x2 block of up to four greys instead:
//13 grey steps rather than 6, so ceilings and floors keep their detail in
//shadow instead of turning into flat grey.  Level 15 (full light) keeps
//the texture's own pixels.
Bool DoomIsGrey(I64 c)
{
  return c==BLACK||c==DKGRAY||c==LTGRAY||c==WHITE;
}

U0 InitLightTable() {
  CBGR48 pal[16];
  static I64 grey[4]={BLACK,DKGRAY,LTGRAY,WHITE};
  F64 best_dist,cur_dist,dr,dg,db,k,mr[256],mg[256],mb[256],
        gr4[35],gg4[35],gb4[35];
  I64 y,code,i,a,b,c,d,n=0,best,g4[35][4];
  GrPaletteGet(pal);
  for(i=0;i!=256;i++) {
    mr[i]=(ToF64(pal[i&0xf].r)+ToF64(pal[i>>4].r))/2.;
    mg[i]=(ToF64(pal[i&0xf].g)+ToF64(pal[i>>4].g))/2.;
    mb[i]=(ToF64(pal[i&0xf].b)+ToF64(pal[i>>4].b))/2.;
  }
//All 35 multisets of 4 greys, sorted dark to light (a<=b<=c<=d).
  for(a=0;a!=4;a++)
    for(b=a;b!=4;b++)
      for(c=b;c!=4;c++)
        for(d=c;d!=4;d++) {
          g4[n][0]=grey[a];
          g4[n][1]=grey[b];
          g4[n][2]=grey[c];
          g4[n][3]=grey[d];
          gr4[n]=(ToF64(pal[grey[a]].r)+ToF64(pal[grey[b]].r)+
                ToF64(pal[grey[c]].r)+ToF64(pal[grey[d]].r))/4.;
          gg4[n]=(ToF64(pal[grey[a]].g)+ToF64(pal[grey[b]].g)+
                ToF64(pal[grey[c]].g)+ToF64(pal[grey[d]].g))/4.;
          gb4[n]=(ToF64(pal[grey[a]].b)+ToF64(pal[grey[b]].b)+
                ToF64(pal[grey[c]].b)+ToF64(pal[grey[d]].b))/4.;
          n++;
        }
  for(code=0;code!=0x100;code++) {
//Full light: copy the texture's own two pixels.
    light_mat[code][15].u16[0]=(code&0xf)|(code>>4)<<8;
    light_mat[code][15].u16[1]=(code&0xf)<<8|code>>4;
    for(y=1;y!=16;y++) {
//y goes up to 15,20 so not totally dark
      k=(20.-y)/20.;
      dr=mr[code]*k;
      dg=mg[code]*k;
      db=mb[code]*k;
      best_dist=1e100;
      best=0;
      if(DoomIsGrey(code&0xf)&&DoomIsGrey(code>>4)) {
        for(i=0;i!=35;i++) {
          cur_dist=Sqr(dr-gr4[i])+Sqr(dg-gg4[i])+Sqr(db-gb4[i]);
          if(cur_dist<best_dist) {
            best_dist=cur_dist;
            best=i;
          }
        }
//Darkest/2nd-darkest on one diagonal, the two lighter on the other.
        light_mat[code][15-y].u8[0]=g4[best][0];
        light_mat[code][15-y].u8[1]=g4[best][2];
        light_mat[code][15-y].u8[2]=g4[best][3];
        light_mat[code][15-y].u8[3]=g4[best][1];
      } else {
        for(i=0;i!=TRANSPARENT;i++) {
          cur_dist=Sqr(dr-mr[i])+Sqr(dg-mg[i])+Sqr(db-mb[i]);
          if(cur_dist<best_dist) {
            best_dist=cur_dist;
            best=i;
          }
        }
//Swap the pixels as .u16[1] is the 2nd "dither" pixel
        light_mat[code][15-y].u8[0]=best&0xf;
        light_mat[code][15-y].u8[1]=best>>4;
        light_mat[code][15-y].u8[2]=best>>4;
        light_mat[code][15-y].u8[3]=best&0xf;
      }
    }
  }
}
InitLightTable;
InitGodmodeTable;
