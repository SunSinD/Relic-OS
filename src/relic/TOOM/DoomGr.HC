/**
 * TempleOS has 16 colors,so I will convert the Doom graphics to
 * 16 colors. I will do this by VECTORizing the "distances" of the Red,Blue and 
 * Green poop ants(Claytonese for distances).
 *
 * I will choose the least poopy ant(Claytonese for distance) and choose that.
 * Dont ask me how to choose a proper palette.
 */

static U8 *doom_palette_dithered=NULL;

U8 *DitherPalette(CRGB *data) {
  U8 *ret=MAlloc(16*16);
  CBGR48 palette48[16];
  I64 x,y,c1,c2,best_color;
  F64 best_dist,dist;
  CRGB normal[16],cur_pixel,mix;
  GrPaletteGet(palette48);
  for(x=0;x!=16;x++) {
    normal[x].r=ToF64(palette48[x].r)/0xffff*0xff;
    normal[x].g=ToF64(palette48[x].g)/0xffff*0xff;
    normal[x].b=ToF64(palette48[x].b)/0xffff*0xff;
  }
  for(x=0;x!=16;x++) {
    for(y=0;y!=16;y++) {
      cur_pixel=data[x+y*16];
      best_color=0;
      best_dist=1e100;
      if(!cur_pixel.a)  {
        for(c1=0;c1!=16;c1++) {
	  for(c2=0;c2!=16;c2++) {
	    mix.r=(normal[c1].r+normal[c2].r)/2;
	    mix.g=(normal[c1].g+normal[c2].g)/2;
	    mix.b=(normal[c1].b+normal[c2].b)/2;
	    dist=Sqrt(Sqr(mix.r-cur_pixel.r)+
		  Sqr(mix.g-cur_pixel.g)+
		  Sqr(mix.b-cur_pixel.b));
	    if(dist<best_dist) {
	      best_dist=dist;
	      best_color=c1|c2<<4;
	    }
	  }
        }
        ret[x+y*16]=best_color;
      } else
        ret[x+y*16]=TRANSPARENT;
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
  U32 stable;
//Make 0x0102 into 0x12
  if(dith&0xff==TRANSPARENT)
    return 0xffffffff;//4 TRANSPARENTs
  light;
  distance;
  god_mode;
  stable.u8[0]=dith&0xf;
  stable.u8[1]=(dith>>8)&0xf;
  stable.u8[2]=(dith>>8)&0xf;
  stable.u8[3]=dith&0xf;
  return stable;
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
  CBGR48 pal[16],dimmed,raw_color;
  F64 best_dist,cur_dist;
  GrPaletteGet(pal);
  static I64 gray[4]={LTGRAY,DKGRAY,BLACK,WHITE};
  I64 ix,best_color,c1,iy;
  for(iy=0;iy!=0x100;iy++) {
    raw_color.r=ToF64(pal[iy&0xf].r+pal[iy>>4].r)/2.;
    raw_color.g=ToF64(pal[iy&0xf].g+pal[iy>>4].g)/2.;
    raw_color.b=ToF64(pal[iy&0xf].b+pal[iy>>4].b)/2.;
        best_dist=I16_MAX;
        best_color=0;
    for(ix=0;ix!=4;ix++) {
        c1=gray[ix];
        dimmed.r=pal[c1].r;
        dimmed.g=pal[c1].g;
        dimmed.b=pal[c1].b;
//"Invert" the colros
	dimmed.r=U16_MAX-dimmed.r;
	dimmed.g=U16_MAX-dimmed.g;
	dimmed.b=U16_MAX-dimmed.b;
        cur_dist=Sqrt(Sqr(dimmed.r-raw_color.r)+
	      Sqr(dimmed.g-raw_color.g)+
	      Sqr(dimmed.b-raw_color.b));
//Pick the most opposite color as the palette is inverse
        if(cur_dist<best_dist) {
	  best_dist=cur_dist;
	  best_color=c1|c1<<4;
        }
    }
    godmode_mat[iy].u8[0]=best_color&0xf;
    godmode_mat[iy].u8[1]=best_color&0xf;
    godmode_mat[iy].u8[2]=best_color&0xf;
    godmode_mat[iy].u8[3]=best_color&0xf;
  }
}
U0 InitLightTable() {
  CBGR48 pal[16],dimmed,mix;
  F64 best_dist,cur_dist;
  GrPaletteGet(pal);
  I64 y,x,ix,iy,iy2,best_color;
  for(y=0;y!=16;y++) {
    for(x=0;x!=16;x++) {
      for(ix=0;ix!=16;ix++) {
        if(!y) {
//just copy the pixels over
	  light_mat[ix<<4|x][15].u16[0]=x|ix<<8;
	  light_mat[ix<<4|x][15].u16[1]=x<<8|ix;
        } else {
	  best_dist=I16_MAX;
	  best_color=0;
//y goes up to 15,20 so not totally dark
	  dimmed.r=ToF64(pal[x].r+pal[ix].r)/2.*(20.-y)/20;
	  dimmed.g=ToF64(pal[x].g+pal[ix].g)/2.*(20.-y)/20;
	  dimmed.b=ToF64(pal[x].b+pal[ix].b)/2.*(20.-y)/20;
	  for(iy=0;iy!=16;iy++) {
	    for(iy2=0;iy2!=16;iy2++) {
	      mix.r=(pal[iy].r+pal[iy2].r)/2;
	      mix.g=(pal[iy].g+pal[iy2].g)/2;
	      mix.b=(pal[iy].b+pal[iy2].b)/2;
	      cur_dist=Sqrt(Sqr(dimmed.r-mix.r)+
		    Sqr(dimmed.g-mix.g)+
		    Sqr(dimmed.b-mix.b));
	      if(cur_dist<best_dist) {
	        best_dist=cur_dist;
	        best_color=iy|iy2<<4;
	      }
	    }
	  }
	  light_mat[ix<<4|x][15-y].u8[0]=best_color&0xf;
	  light_mat[ix<<4|x][15-y].u8[1]=best_color>>4;
	  light_mat[ix<<4|x][15-y].u8[2]=best_color>>4;
	  light_mat[ix<<4|x][15-y].u8[3]=best_color&0xf;
        }
      }
    }
  }
}
InitLightTable;
InitGodmodeTable;
