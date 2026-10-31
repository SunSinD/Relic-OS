// TempleOS boot stage 2 and installer, adapted for automatic boot.
// Original by Terry A. Davis, public domain. Esc opens recovery.
#define RELIC_BOOT_MODULE_SIZE		2*BLK_SIZE
#define RELIC_BOOT_HIGH_LOC_MHD2	((BOOT_RAM_LIMIT-\
				(BOOT_STK_SIZE+RELIC_BOOT_MODULE_SIZE))>>4)

DefinePrint(
  "DD_RELIC_BOOT_HIGH_LOC_MHD2","%08X",RELIC_BOOT_HIGH_LOC_MHD2<<4);

asm {
USE16
RELIC_BMHD2_START::
	MOV	U32 FS:[0],'B'+0x2000+('2'+0x2000)<<16

	MOV	AX,RELIC_BOOT_HIGH_LOC_MHD2
	MOV	ES,AX
//This copies this bootloader's code to 0x$TX,"00096A00",D="DD_RELIC_BOOT_HIGH_LOC_MHD2"$
	MOV	AX,CS
	MOV	DS,AX
	MOV	U32 [RELIC_BMHD2_OLD_CS_RIP-RELIC_BMHD2_START],EBX
	MOV	U8 [RELIC_BMHD2_BIOS_DRV_NUM-RELIC_BMHD2_START],DL

	MOV	CX,RELIC_BOOT_MODULE_SIZE
	XOR	SI,SI
	XOR	DI,DI
	REP_MOVSB

	MOV	AX,RELIC_BOOT_HIGH_LOC_MHD2
	MOV	DS,AX

//My assembler doesn't support 16-bit very well.
	DU8	0xEA;	//JMP RELIC_BOOT_HIGH_LOC_MHD2:RELIC_BMHD2_HISTART
	DU16	RELIC_BMHD2_HISTART-RELIC_BMHD2_START,RELIC_BOOT_HIGH_LOC_MHD2;

RELIC_BMHD2_BOOT_MSG::
	DU8	256 DUP(0);

RELIC_BMHD2_BIOS_DRV_NUM:	DU8	0;
RELIC_BMHD2_PAGE:		DU8	0;
RELIC_BMHD2_BLK_ARRAY::	DU64 8 DUP(0);

RELIC_BMHD2_DAP:		DU8	16,0,1,0; //One blk at a time
RELIC_BMHD2_DAP_BUF:		DU16	0,0;
RELIC_BMHD2_DAP_BLK::	//64-bit
RELIC_BMHD2_DAP_BLK_LO:	DU32	0;
RELIC_BMHD2_DAP_BLK_HI:	DU32	0;

RELIC_BMHD2_PUT_CHAR::
	MOV	AH,0xE
	MOV	BL,7 //Might be foreground color on some BIOS's
	MOV	BH,U8 [RELIC_BMHD2_PAGE-RELIC_BMHD2_START]
	INT	0x10
RELIC_BMHD2_RET::
	RET
RELIC_BMHD2_PUTS::
@@1:	LODSB
	TEST	AL,AL
	JZ	RELIC_BMHD2_RET
	CALL	RELIC_BMHD2_PUT_CHAR
	JMP	@@1

RELIC_BMHD2_MENU_WAIT: DU8 0;
RELIC_BMHD2_DEFAULT:: DU8 0;
RELIC_BMHD2_GETCHAR:
    CMP U8 [RELIC_BMHD2_MENU_WAIT-RELIC_BMHD2_START],0
    JNE RELIC_BMHD2_KEY_READY
    PUSH BX
    XOR AH,AH
    INT 0x1A
    MOV BX,DX
RELIC_BMHD2_KEY_POLL:
    MOV AH,1
    INT 0x16
    JNZ RELIC_BMHD2_HAVE_KEY
    XOR AH,AH
    INT 0x1A
    SUB DX,BX
    CMP DX,18
    JB RELIC_BMHD2_KEY_POLL
    POP BX
    MOV AL,U8 [RELIC_BMHD2_DEFAULT-RELIC_BMHD2_START]
    RET
RELIC_BMHD2_HAVE_KEY:
    POP BX
RELIC_BMHD2_KEY_READY:
    XOR AH,AH
    INT 0x16
    CMP AL,27
    JNE RELIC_BMHD2_KEY_ECHO
    MOV U8 [RELIC_BMHD2_MENU_WAIT-RELIC_BMHD2_START],1
    MOV SI,RELIC_BMHD2_BOOT_MSG-RELIC_BMHD2_START
    CALL RELIC_BMHD2_PUTS
    JMP RELIC_BMHD2_KEY_READY
RELIC_BMHD2_KEY_ECHO:
    PUSH AX
	MOV	AH,0x0E
	MOV	BX,0x07
	INT	0x10
	POP	AX
	RET

RELIC_BMHD2_HISTART:
	MOV	AH,0xF
	INT	0x10
	MOV	U8 [RELIC_BMHD2_PAGE-RELIC_BMHD2_START],BH //Video page

	MOV	U32 FS:[0],0
@@5:    CMP U8 [RELIC_BMHD2_MENU_WAIT-RELIC_BMHD2_START],0
    JE RELIC_BMHD2_SKIP_MSG
    MOV SI,RELIC_BMHD2_BOOT_MSG-RELIC_BMHD2_START
    CALL RELIC_BMHD2_PUTS
RELIC_BMHD2_SKIP_MSG:
	CALL	RELIC_BMHD2_GETCHAR
	CMP	AL,'0'
	JB	@@5
	CMP	AL,'8'
	JAE	@@5
	AND	EAX,7

	MOV	EBX,U32 RELIC_BMHD2_BLK_ARRAY-RELIC_BMHD2_START[EAX*8]
	MOV	EAX,U32 RELIC_BMHD2_BLK_ARRAY+4-RELIC_BMHD2_START[EAX*8]

	TEST	EBX,EBX
	JNZ	@@10
	TEST	EAX,EAX
	JZ	@@5

@@10:	MOV	U32 [RELIC_BMHD2_DAP_BLK_LO-RELIC_BMHD2_START],EBX
	MOV	U32 [RELIC_BMHD2_DAP_BLK_HI-RELIC_BMHD2_START],EAX

	MOV	AX,U16 [RELIC_BMHD2_OLD_CS_RIP-RELIC_BMHD2_START]
	SHR	AX,4
	ADD	AX,U16 [RELIC_BMHD2_OLD_CS_RIP+2-RELIC_BMHD2_START]
	MOV	U16 [RELIC_BMHD2_DAP_BUF+2-RELIC_BMHD2_START],AX //ES:0000
	MOV	SI,RELIC_BMHD2_DAP-RELIC_BMHD2_START //DS:SI=DAP
	MOV	DL,U8 [RELIC_BMHD2_BIOS_DRV_NUM-RELIC_BMHD2_START]
	MOV	AH,0x42
	INT	0x13

	POP	EBP
	POP	EDX
	POP	EBX
	POP	ECX
	XOR	EAX,EAX
	POP	GS
	POP	FS
	POP	ES
	POP	DS
	POPFW

//My assembler doesn't support 16-bit very well.
	DU8	0xEA;	//JMP xxxx:yyyy
RELIC_BMHD2_OLD_CS_RIP:
	DU16	0,0;
RELIC_BMHD2_END::
//Continues here $LK,"::/Adam/Opt/Boot/BootHD.HC",A="FF:::/Adam/Opt/Boot/BootHD.HC,START"$
#assert RELIC_BMHD2_END-RELIC_BMHD2_START<RELIC_BOOT_MODULE_SIZE
}

public Bool RelicBootAutoInstall(U8 drv_let,U8 *drv_lst=NULL)
{//Create new MBR on the disk that has drv_let as a partition.
//Puts stage 2 in BOOT_DIR of drv_let.
  CBlkDev *bd,*bd1;
  CDrv *dv,*p1;
  CMasterBoot mbr;
  CDirEntry de;
  I64 i,j,size,*_q;
  U8 *menu_ptr,*ptr,*old_dir,ch,buf[STR_LEN];
  Bool res=FALSE;

  if (!DrvIsWritable(drv_let)) return FALSE;
  if (drv_lst && StrLen(drv_lst)>=sizeof(buf)) return FALSE;
  old_dir=DirCur;
  try {
    if (drv_lst) {
      StrCpy(buf,drv_lst);
      StrUtil(buf,SUF_TO_UPPER);
    } else {
      buf[0]=drv_let; buf[1]=0;
    }
    Drv(drv_let);
    dv=Fs->cur_dv;
    if (dv->fs_type!=FSt_REDSEA && dv->fs_type!=FSt_FAT32)
      PrintErr("File System Not Supported\n");
    else {
      bd=dv->bd;
      if (!FileFind(BOOT_DIR_OLDMBR_BIN_C,,FUF_JUST_FILES))
	BootMHDOldRead(drv_let,drv_let);

      _q=RELIC_BMHD2_BLK_ARRAY;
      MemSet(_q,0,sizeof(I64)*8);
      menu_ptr=RELIC_BMHD2_BOOT_MSG;
      StrPrint(menu_ptr,"\n\r\n\rRelicOS recovery (normal boot is automatic)\n\r\n\r");
      j=0;
      *RELIC_BMHD2_DEFAULT(U8 *)=0;
      if (FileFind(BOOT_DIR_OLDMBR_BIN_C,&de,FUF_JUST_FILES)) {
	Free(de.full_name);
	*_q++=Clus2Blk(dv,de.clus);
	CatPrint(menu_ptr,"0. Old Boot Record\n\r");
	j++;
      }

      if (!j) throw('OldMBR');
      ptr=buf;
      while (j<8 && (ch=*ptr++)) {
	if ((p1=Let2Drv(ch,FALSE)) && (bd1=p1->bd) && bd1==bd) {
	  *_q=p1->drv_offset;
          if (p1==dv && *_q) *RELIC_BMHD2_DEFAULT(U8 *)='0'+j;
	  "Drive %C:%16X\n",Drv2Let(p1),*_q;
	  CatPrint(menu_ptr,"%d. Drive %C\n\r",j++,Drv2Let(p1));
	  _q++;
	}
      }
      if (!*RELIC_BMHD2_DEFAULT(U8 *)) throw('BootDrv');
      CatPrint(menu_ptr,"\n\rSelection:");

      size=RELIC_BMHD2_END-RELIC_BMHD2_START;
      FileWrite(BOOT_DIR_BOOTMHD2_BIN_C,RELIC_BMHD2_START,size);

      if (!FileFind(BOOT_DIR_BOOTMHD2_BIN_C,&de,FUF_JUST_FILES))
	"No Boot Loader Image\n";
      else {
	Free(de.full_name);
	*BMHD_BLK_CNT(U16 *)=(size+BLK_SIZE-1)>>BLK_SIZE_BITS;
	*BMHD_DAP_BLK(I64 *)=Clus2Blk(dv,de.clus);
//Bypass partition bounds-checking
	BlkDevLock(bd);
	ATAReadBlks(bd,&mbr,0,1);
	for (i=0;i<BMHD_END-BMHD_CODE;i++)
	  mbr.code[i]=BMHD_CODE(U8 *)[i];
#assert sizeof(CMasterBoot.code)>=BMHD_END-BMHD_CODE
	for (;i<sizeof(CMasterBoot.code);i++)
	  mbr.code[i]=0;
	if (!mbr.media_id)
	  mbr.media_id=RandU32;
	mbr.zero=0;
	mbr.signature=0xAA55;

	ATAWriteBlks(bd,&mbr,0,1);
	BlkDevUnlock(bd);
	res=TRUE;
      }
    }
  } catch {
    Fs->catch_except=TRUE;
    PutExcept;
  }
  Cd(old_dir); Free(old_dir);
  return res;
}
