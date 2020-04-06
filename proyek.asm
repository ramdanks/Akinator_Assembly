IDEAL
MODEL small
STACK 0F500H

MAX_BMP_WIDTH = 320 
MAX_BMP_HEIGHT = 200  
SMALL_BMP_HEIGHT = 40 
SMALL_BMP_WIDTH = 40

UpArrow = 'w'
DownArrow = 's'
LeftArrow = 'a'
RightArrow = 'd'
EnterKey = 13

;==========!(DATA SEGMENT)!===========;

       DATASEG

Index       db   1
CLOCK       EQU  ES:6CH

Step        db   1
ANSWER      dw   500
UPBOUND     dw   1000
LOWBOUND    dw   0

VARNAME     db  16 dup(0)
MSG         db  "Masukkan Nama Anda : ", 0

;=============== BMP INFO ===============;

OneBmpLine 	    db MAX_BMP_WIDTH dup (0)
ScreenLineMax 	db MAX_BMP_WIDTH dup (0)

ErrorFile   db  0
FileHandle  dw  ?
Header      db  54 dup(0)
Palette     db  400H dup(0)

BmpLeft     dw  ?
BmpTop      dw  ?
BmpColSize  dw  ?
BmpRowSize  dw  ?

;=== PICTURE ===;

ANS_DECI    db "501.bmp", 0
NumberImg   db "assets\num\501.bmp", 0
NumberOV1	db "assets\num\1000.bmp", 0
NumberOV2	db "assets\num\1001.bmp", 0


MenuImg1    db "assets\menu\sel1.bmp", 0
MenuImg2    db "assets\menu\sel2.bmp", 0
MenuImg3    db "assets\menu\sel3.bmp", 0
MenuImg4    db "assets\menu\sel4.bmp", 0

ChooseImg1  db "assets\game\choose1.bmp", 0
ChooseImg2  db "assets\game\choose2.bmp", 0
ChooseImg3  db "assets\game\choose3.bmp", 0

DoneImg1    db "assets\step\1step.bmp", 0
DoneImg2    db "assets\step\2step.bmp", 0
DoneImg3    db "assets\step\3step.bmp", 0
DoneImg4    db "assets\step\4step.bmp", 0
DoneImg5    db "assets\step\5step.bmp", 0
DoneImg6    db "assets\step\6step.bmp", 0
DoneImg7    db "assets\step\7step.bmp", 0
DoneImg8    db "assets\step\8step.bmp", 0
DoneImg9    db "assets\step\9step.bmp", 0
DoneImg10   db "assets\step\10step.bmp", 0

BlankImg    db "assets\blank.bmp", 0	

;==========!(CODE SEGMENT)!===========;

       CODESEG

;==== ENTRY POINT ====;

        START:

MOV  AX,     @data
MOV  DS,     AX
CALL SetResolution

;==== MENU POINT ====;
        
        MENU:
        
CALL MenuImgProc
CALL Input
CALL MenuSelProc

CMP  AL, 10
JE   GAME
CMP  AL, 20
JE   HOW
CMP  AL, 30
JE   CREDITS

JMP  MENU

;==== GAME POINT ====;

        GAME:

CALL InitNewGame        

UpdateAnswer:
    CALL ChangeNumberImgProc
    CALL NumberSelProc
    
    Selection:
    CALL GameImgProc
    CALL GameSelProc
    CMP  AL, 10
    JE   UpdateAnswer
    CMP  AL, 'm'
    JE   MENU
    CMP  AL, 20
    JE   DONE
    JMP  Selection

        DONE:

CALL DoneImgProc
CALL Input
CMP  AL, 't'
JE   NEXT
CMP  AL, 'm'
JNE  DONE

MOV [STEP], 1
CALL Sound
JMP  MENU

NEXT:
CALL TESTIMONY
JMP  MENU  

;==== HOWTO POINT ====;

         HOW:
         
LEA  DX, [BlankImg]
CALL OpenShowBmp

AskHowInput:       
CALL INPUT
CMP  AL, 'm'
JNE  AskHowInput

CALL SOUND
JMP  MENU

;=== CREDITS POINT ===;
        
       CREDITS:

LEA  DX, [BlankImg]
CALL OpenShowBmp

AskCreditsInput:       
CALL INPUT        
CMP  AL, 'm'
JNE  AskCreditsInput

CALL Sound
JMP  MENU

;==========!(MACRO SEGMENT)!===========;

;==== SOUND ====;

PROC Sound

    mov al,  182       
    out 43h, al       
    mov ax,  5600      
    out 42h, al       
    mov al,  ah          
    out 42h, al               
    in  al,  61h         
    or  al,  00000011b  
    out 61h, al
    
    CALL DELAY
    
    IN  AL,  61H
    AND AL,  11111100B
    OUT 61H, AL
    RET
             
RET    
ENDP Sound

;==== Game Logic Here ====;

PROC GameLogic
  
    CMP  [STEP], 10
    JAE  RETURN
    
    MOV  DX, [ANSWER]
    CHECKDOWN:    
    CMP  AL, 10
    JNE  CHECKUP
    INC  [STEP]
    MOV  [LOWBOUND], DX
    MOV  DX, [UPBOUND]
    SUB  DX, [LOWBOUND]
    MOV  AX, DX
    MOV  BX, 2
    CWD
    DIV  BX
    CMP  DX, 0
    JE   Lanjutan
    INC  AX
    Lanjutan:
    MOV  DX, AX
    ADD  DX, [LOWBOUND]
    JMP  RETURN
    
    CHECKUP:
    CMP  AL, 30
    JNE  RETURN
    INC  [STEP] 
    MOV  [UPBOUND], DX
    SUB  DX, [LOWBOUND]
    SHR  DX, 1
    ADD  DX, [LOWBOUND]  
    
RETURN:
MOV  [ANSWER], DX
MOV  AL, 10
RET
ENDP

PROC InitNewGame
    
    MOV AL, 0
    MOV [STEP], 1
    MOV [UPBOUND], 1000
    MOV [LOWBOUND], 0
    MOV [ANSWER], 500
    
RET
ENDP

;==== Number in Game Done ====;

PROC ChangeNumberImgProc
		
	MOV  AX, [ANSWER]
	
	checkOV1:
	CMP  AX, 999
	JNE  checkOV2
	LEA  DX, [NumberOV1]
	JMP  ReturnImmideately
	
	checkOV2:
	CMP  AX, 1000
	JNE  NotOverload
	LEA  DX, [NumberOV2]
	JMP  ReturnImmideately
	
    NotOverload:
    MOV  DI, offset ANS_DECI
	INC  AX
	MOV  BX, 0Ah
	
	DIV  BL
	ADD  AH, 30h
	MOV	 [DI+2], AH
	SUB  AH, 30h 
	MOV  AH, 0h
	DIV  BL
	ADD  AH, 30h
	MOV	 [DI+1], AH 
	SUB  AH, 30h
	MOV  AH, 0h
	DIV  BL 
	ADD  AH, 30h
	MOV	 [DI], AH
    SUB  AH, 30h
    
    MOV  SI, offset ANS_DECI
	MOV  DI, offset NumberImg
	ADD  DI, 0Bh
	MOV  AH, 00h
	
	MOV CX, 7
	append:
		LODSB
		MOV  [DI], AX
		INC  DI
		loop append
	MOV  AX,00h
   
   LEA  DX, [NumberImg]
   ReturnImmideately:
   CALL OpenShowBmp
 
RET    
ENDP ChangeNumberImgProc

PROC NumberSelProc
    
    AskAgain:
    CALL Input
    CMP  AL, 'r'
    JNE  AskAgain    

RET    
ENDP NumberSelProc

;=== Testimony when Game Done ===;

PROC Testimony

    LEA DX, [MSG]
    MOV AH, 09H
    INT 21H
    
    LEA BP, [VARNAME]
    MOV DI, 0
    GetInput:
    MOV AH, 01H
    INT 21H
    MOV [BP+DI], AL
    INC DI
    CMP DI, 16
    JAE KembaliTestimony
    CMP AL, 13
    JE  KembaliTestimony
    JMP GetInput

KembaliTestimony:
RET
ENDP Testimony    


;==== Image when Game Done ====;

PROC DoneImgProc
    
    STEP1:
    CMP [Step], 1
    JNE STEP2
    LEA DX, [DoneImg1]
    STEP2:
    CMP [Step], 2
    JNE STEP3
    LEA DX, [DoneImg2]
    STEP3:
    CMP [Step], 3
    JNE STEP4
    LEA DX, [DoneImg3]
    STEP4:
    CMP [Step], 4
    JNE STEP5
    LEA DX, [DoneImg4]
    STEP5:
    CMP [Step], 5
    JNE STEP6
    LEA DX, [DoneImg5]
    STEP6:
    CMP [Step], 6
    JNE STEP7
    LEA DX, [DoneImg6]
    STEP7:
    CMP [Step], 7
    JNE STEP8
    LEA DX, [DoneImg7]
    STEP8:
    CMP [Step], 8
    JNE STEP9
    LEA DX, [DoneImg8]
    STEP9:
    CMP [Step], 9
    JNE STEP10
    LEA DX, [DoneImg9]
    STEP10:
    CMP [Step], 10
    JB  KembaliDoneImgProc
    LEA DX, [DoneImg10]
        
KembaliDoneImgProc:
CALL OpenShowBmp    
RET
ENDP DoneImgProc

;==== Image in Game Mode ====;

PROC GameImgProc

    LEFT_CHOOSE:
    LEA DX, [ChooseImg1]
    
    MID_CHOOSE:
    CMP [Index], 2
    JNE RIGHT_CHOOSE
    LEA DX, [ChooseImg2]
    
    RIGHT_CHOOSE:
    CMP [Index], 3
    JNE KembaliGameImgProc
    LEA DX, [ChooseImg3]

KembaliGameImgProc:
CALL OpenShowBmp
RET        
ENDP GameImgProc

;==== Select in Game Mode ====;

;AL = 10, User Press (Too Low) or (Too High) Button, Return by GameLogic
;AL = 20, User Press (Mid Button)
                              
PROC GameSelProc
    
    CALL Input
    
Game_PressEnter:    
    CMP  AL, 13
    JNE  Game_PressLeft
    CALL Sound
    MOV  AL, 10
    
    TOO_LOW:
    CMP  [Index], 1
    JNE  IS_CORRECT
    MOV  AL, 10
    CALL GameLogic
    
    IS_CORRECT:
    CMP  [Index], 2
    JNE  TOO_HIGH
    MOV  AL, 20
    
    TOO_HIGH:
    CMP  [Index], 3
    JNE  KembaliGameSelProc
    MOV  AL, 30
    CALL GameLogic
    
    JMP KembaliGameSelProc

Game_PressLeft:
    CMP AL, LeftArrow
    JNE Game_PressRight
    CMP [Index], 1
    JBE KembaliGameSelProc
    DEC [Index]
    
Game_PressRight:
    CMP AL, RightArrow
    JNE Kembali
    CMP [Index], 3
    JAE KembaliGameSelProc
    INC [Index]
    
KembaliGameSelProc:
RET     
ENDP GameSelProc

;==== Image in Menu Mode ====;

PROC MenuImgProc
     
    INDEX1:
    LEA DX, [MenuImg1]
    
    INDEX2:
    CMP [Index], 2
    JNE INDEX3
    LEA DX, [MenuImg2]
    
    INDEX3:
    CMP [Index], 3
    JNE INDEX4
    LEA DX, [MenuImg3]
    
    INDEX4:
    CMP [Index], 4
    JNE KembaliMenuImgProc
    LEA DX, [MenuImg4]
     
KembaliMenuImgProc:
CALL OpenShowBmp     
RET
ENDP MenuImgProc

;==== Select in Menu Mode ====;

PROC MenuSelProc

PressEnter:
    CMP AL, EnterKey
    JNE PressUp
    Call Sound
    
    SelectPlay:
    CMP [Index], 1
    JNE SelectHow
    MOV AL, 10
    
    SelectHow:
    CMP [Index], 2
    JNE SelectCredits
    MOV AL, 20    
    
    SelectCredits:
    CMP [Index], 3
    JNE SelectExit
    MOV AL, 30    
    
    SelectExit:
    CMP [Index], 4
    JNE PressUp
    CALL ExitProg

PressUp:
    CMP AL, UpArrow
    JNE PressDown
    CMP [Index], 1
    JBE Kembali
    DEC [Index]
    
PressDown:    
    CMP AL, DownArrow
    JNE Kembali
    CMP [Index], 4
    JAE Kembali
    INC [Index]
    
Kembali:
RET     
ENDP MenuSelProc

;==== Handle BMP Image Format ====;

PROC OpenShowBmp NEAR
	push cx
	push bx
	call OpenBmpFile
	cmp [ErrorFile],1
	je @@ExitProc
	call ReadBmpHeader
	call ReadBmpPalette
	call CopyBmpPalette 
	call ShowBMP 
	call CloseBmpFile
	@@ExitProc:
	pop bx
	pop cx
RET
ENDP OpenShowBmp

PROC OpenBmpFile NEAR						 
	mov ah, 3Dh
	xor al, al
	int 21h
	jc @@ErrorAtOpen
	mov [FileHandle], ax
	jmp @@ExitProc	
@@ErrorAtOpen:
	mov [ErrorFile],1
@@ExitProc:	
RET
ENDP OpenBmpFile

PROC CloseBmpFile near
	mov ah,3Eh
	mov bx, [FileHandle]
	int 21h
RET
ENDP CloseBmpFile
PROC ReadBmpHeader NEAR					
	push cx
	push dx
	mov ah,3fh
	mov bx, [FileHandle]
	mov cx,54
	mov dx,offset Header
	int 21h
	pop dx
	pop cx
RET
ENDP ReadBmpHeader

PROC ReadBmpPalette NEAR 	
	push cx
	push dx
	mov ah,3fh
	mov cx,400h
	mov dx,offset Palette
	int 21h
	pop dx
	pop cx
RET
ENDP ReadBmpPalette

PROC CopyBmpPalette	NEAR					
	push cx
	push dx
	mov si,offset Palette
	mov cx,256
	mov dx,3C8h
	mov al,0  							
	out dx,al 
	inc dx	  
CopyNextColor:
	mov al,[si+2] 						
	shr al,2 							
	out dx,al 						
	mov al,[si+1] 						
	shr al,2            
	out dx,al 							
	mov al,[si] 						
	shr al,2            
	out dx,al 							
	add si,4 						
	loop CopyNextColor
	pop dx
	pop cx
RET
ENDP CopyBmpPalette

PROC ShowBMP 
	push cx
	mov ax, 0A000h
	mov es, ax
	mov cx,[BmpRowSize]
	mov ax,[BmpColSize] ; row size must dived by 4 so if it less we must calculate the extra padding bytes
	xor dx,dx
	mov si,4
	div si
	mov bp,dx
	mov dx,[BmpLeft]
@@NextLine:
	push cx
	push dx
	mov di,cx  ; Current Row at the small bmp (each time -1)
	add di,[BmpTop] ; add the Y on entire screen
	mov cx,di
	shl cx,6
	shl di,8
	add di,cx
	add di,dx
	mov ah,3fh
	mov cx,[BmpColSize]  
	add cx,bp  ; extra  bytes to each row must be divided by 4
	mov dx,offset ScreenLineMax
	int 21h
	cld ; Clear direction flag, for movsb
	mov cx,[BmpColSize]  
	mov si,offset ScreenLineMax
	rep movsb ; Copy line to the screen
	pop dx
	pop cx
	loop @@NextLine
	pop cx
RET
ENDP ShowBMP

PROC  SetResolution
    
	MOV AX,         13H   ; 320 X 200 
	INT 10H
	MOV [BmpLeft],    0
	MOV [BmpTop],     0
	MOV [BmpColSize], 320
	MOV [BmpRowSize], 200
RET
ENDP SetResolution

PROC Input

    MOV AH, 07H
    INT 21H
RET
ENDP Input

;==== DELAY (DX) ====;

PROC DELAY

push ax                   
  mov ax,40h               
  mov es,ax                 
  mov ax,[clock]            

  Ketukawal:
    cmp ax, [clock]
    mov cx, 1               
    je Ketukawal

  Loopdelay:
    mov ax, [clock]
    ketuk:
       cmp ax,[clock]
       je ketuk
       loop Loopdelay
       pop ax
    ret

ENDP DELAY

;==== Exit Program ====;

PROC ExitProg
    
    MOV AX, 2
    INT 10H
    MOV AX, 4C00H
    INT 21H

ENDP ExitProg

;======================;
     
END