IDEAL
MODEL small
STACK 0F500H

MAX_BMP_WIDTH = 320 
MAX_BMP_HEIGHT = 200  
SMALL_BMP_HEIGHT = 40 
SMALL_BMP_WIDTH = 40

UpArrow = 'w'
DownArrow = 's'
EnterKey = 13

;==!(DATA SEGMENT)!==;

       DATASEG

MenuIndex   db   1
CLOCK       EQU  ES:6CH

;=============== BMP INFO ===============;

OneBmpLine 	    db MAX_BMP_WIDTH dup (0)
ScreenLineMax 	db MAX_BMP_WIDTH dup (0)

ErrorFile   db 0
FileHandle  dw ?
Header      db 54       dup(0)
Palette     db 400H     dup(0)


BmpLeft     dw ?
BmpTop      dw ?
BmpColSize  dw ?
BmpRowSize  dw ?

;=== PICTURE ===;

MenuImg1     db "assets\sel1.bmp", 0
MenuImg2     db "assets\sel2.bmp", 0
MenuImg3     db "assets\sel3.bmp", 0
MenuImg4     db "assets\sel4.bmp", 0	

;==!(CODE SEGMENT)!==;

       CODESEG

;==!(ENTRY - POINT)!==;

        START:

MOV  AX,     @data
MOV  DS,     AX
CALL SetResolution

        MENU:

CALL MenuImgProc
CALL Input
CALL MenuSelProc
JMP  MENU


;==!(MACRO SEGMENT)!==;

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

PROC MenuImgProc
     
    INDEX1:
    LEA DX, [MenuImg1]
    
    INDEX2:
    CMP [MenuIndex], 2
    JNE INDEX3
    LEA DX, [MenuImg2]
    
    INDEX3:
    CMP [MenuIndex], 3
    JNE INDEX4
    LEA DX, [MenuImg3]
    
    INDEX4:
    CMP [MenuIndex], 4
    JNE KembaliImgProc
    LEA DX, [MenuImg4]
     
KembaliImgProc:
CALL OpenShowBmp
CALL Sound     
RET
ENDP MenuImgProc

PROC MenuSelProc

PressEnter:

    CMP AL, EnterKey
    JNE PressUp
    CMP [MenuIndex], 4
    JNE PressUp
    CALL ExitProg

PressUp:

    CMP AL, UpArrow
    JNE PressDown
    CMP [MenuIndex], 1
    JBE Kembali
    DEC [MenuIndex]
    
PressDown:
    
    CMP AL, DownArrow
    JNE Kembali
    CMP [MenuIndex], 4
    JAE Kembali
    INC [MenuIndex]
    
Kembali:
RET     
ENDP MenuSelProc

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

PROC ExitProg
    
    MOV AX, 2
    INT 10H
    MOV AX, 4C00H
    INT 21H

ENDP ExitProg

;====================;
     
END