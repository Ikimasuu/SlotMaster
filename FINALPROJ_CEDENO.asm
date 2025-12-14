.MODEL SMALL
.STACK 100h
; ------------------------------------------------------------
; SlotMaster - Parking Slot Management System
; Console-based, TASM-compatible (real-mode DOS)
; Requirements: in-memory data only, menu-driven CRUD, auth
; Programmer: KHARL PATRICK R. CEDENO
; ------------------------------------------------------------

.DATA
; -------------------- Constants --------------------
MAX_USERS           EQU 5
MAX_USERNAME_LEN    EQU 16
MAX_PASSWORD_LEN    EQU 16
MAX_SLOTS           EQU 10
MAX_PLATE_LEN       EQU 12

STATUS_FREE         EQU 0
STATUS_OCCUPIED     EQU 1
STATUS_DELETED      EQU 2

; -------------------- UI Theme --------------------
; Text mode attribute: (background << 4) | foreground
UI_ATTR_NORMAL      EQU 1Fh    ; bright white on blue
UI_ATTR_TITLE       EQU 1Eh    ; yellow on blue
UI_ATTR_BORDER      EQU 1Bh    ; bright cyan on blue
UI_ATTR_PROMPT      EQU 1Ah    ; bright green on blue
UI_ATTR_ERROR       EQU 1Ch    ; bright red on blue

; -------------------- Text Resources --------------------
openingScreenText   DB 'SlotMaster Parking Slot Management System',13,10
                DB 'Programmer: KHARL PATRICK R. CEDENO',13,10
                DB 'Date: 12/14/2025',13,10,13,10
                DB 'Press any key to continue...$'

authMenuHeader  DB '=== SlotMaster Authentication ===',13,10
                DB '[1] Login',13,10
                DB '[2] Register',13,10
                DB '[3] Exit',13,10,13,10
                DB 'Enter choice: $'
noUsersMsg      DB 'No users registered. Please register first.',13,10
                DB 'Press any key to continue...',0
userLimitMsg    DB 'User storage is full. Cannot register more users.',13,10
                DB 'Press any key to continue...',0
registerOkMsg   DB 'Registration successful. Press any key to return to login...',0
userExistsMsg   DB 'Username already exists. Choose another.',13,10
                DB 'Press any key to continue...',0
loginFailMsg    DB 'Invalid username or password. Try again.',13,10
                DB 'Press any key to retry...',0
loginOkMsg      DB 'Login successful. Loading main menu...',0

loginUserPrompt DB 'Username: $'
loginPassPrompt DB 'Password: $'
loginHeader     DB '=== Login ===',13,10,'$'
registerHeader  DB '=== Register ===',13,10,'$'

mainMenuHeader  DB '=== SlotMaster Main Menu ===',13,10
                DB '[1] Create New Parking Slot Record',13,10
                DB '[2] View All Records',13,10
                DB '[3] Update Slot Record',13,10
                DB '[4] Delete Slot Record',13,10
                DB '[5] Logout',13,10
                DB '[6] Exit Program',13,10,13,10
                DB 'Enter choice: $'

createHeader    DB '--- Create New Parking Slot ---',13,10,'$'
viewHeader      DB '--- View Parking Slots ---',13,10,'$'
updateHeader    DB '--- Update Parking Slot ---',13,10,'$'
deleteHeader    DB '--- Delete Parking Slot ---',13,10,'$'

slotIdPrompt    DB 'Enter slot ID (numeric): $'
statusPrompt    DB 'Enter status (F = FREE, O = OCCUPIED): $'
platePrompt     DB 'Enter plate number: $'
slotExistsMsg   DB 'Duplicate slot ID. Creation rejected.',13,10
                DB 'Press any key to continue...',0
slotCreateOk    DB 'Slot created successfully.',13,10
                DB 'Press any key to continue...',0
slotFullMsg     DB 'Storage full (max 10 slots). Cannot create more slots.',13,10
                DB 'Press any key to continue...',0
invalidInputMsg DB 'Invalid input. Please try again.',13,10
                DB 'Press any key to continue...',0

tableHeader     DB 'Slot ID | Status    | Plate Number',13,10
                DB '-----------------------------------',13,10,'$'
noSlotsMsg      DB 'No active records to display.',13,10
                DB 'Press any key to continue...',0

updateOptions   DB '[1] Change status',13,10
                DB '[2] Change plate number',13,10
                DB '[3] Cancel',13,10,13,10
                DB 'Enter choice: $'
updateOptionsFree DB '[1] Change status',13,10
                 DB '[2] Cancel',13,10,13,10
                 DB 'Enter choice: $'
updateOkMsg     DB 'Record updated successfully.',13,10
                DB 'Press any key to continue...',0

deleteConfirm   DB 'Delete this record? (Y/N): $'
deleteOkMsg     DB 'Record deleted.',13,10
                DB 'Press any key to continue...',0
notFoundMsg     DB 'Record not found or already deleted.',13,10
                DB 'Press any key to continue...',0
continueMsg     DB 13,10,'Press any key to continue...',0
dashMsg         DB '-',0
slotIdLabel     DB 'Slot ID: $'
statusLabel     DB 'Status: $'
plateLabel      DB 'Plate: $'

logoutMsg       DB 'Logging out...',13,10,'$'
exitMsg         DB 'Exiting SlotMaster. Goodbye!$'

statusFreeStr       DB 'FREE$'
statusOccStr        DB 'OCCUPIED$'

crlfStr         DB 13,10,'$'
spaceBar        DB ' $'
pipeSep         DB ' | $'

; -------------------- UI Text Resources (Main Screens) --------------------
uiIndentCol     DB 0

uiOpenTitle     DB 'SLOTMASTER$'
uiOpenSubtitle  DB 'Parking Slot Management System$'
uiOpenByLine    DB 'Programmer: KHARL PATRICK R. CEDENO$'
uiOpenDateLine  DB 'Date: 12/14/2025$'
uiOpenContinue  DB 'Press any key to continue...$'

uiAuthHeader    DB 'AUTHENTICATION$'
uiAuthOpt1      DB '[1] Login$'
uiAuthOpt2      DB '[2] Register$'
uiAuthOpt3      DB '[3] Exit$'
uiAuthPrompt    DB 'Select an option (1-3): $'

uiMainHeader    DB 'MAIN MENU$'
uiMainOpt1      DB '[1] Create New Parking Slot Record$'
uiMainOpt2      DB '[2] View All Records$'
uiMainOpt3      DB '[3] Update Slot Record$'
uiMainOpt4      DB '[4] Delete Slot Record$'
uiMainOpt5      DB '[5] Logout$'
uiMainOpt6      DB '[6] Exit Program$'
uiMainPrompt    DB 'Select an option (1-6): $'

uiInvalidChoice DB 'Invalid choice. Press any key...$'

uiLoginTitle    DB 'LOGIN$'
uiRegisterTitle DB 'REGISTER$'
uiCreateTitle   DB 'CREATE SLOT$'
uiViewTitle     DB 'VIEW PARKING SLOTS$'
uiUpdateTitle   DB 'UPDATE SLOT$'
uiDeleteTitle   DB 'DELETE SLOT$'
uiExitTitle     DB 'GOODBYE$'

uiViewNextPage  DB 'More records available. Press any key for next page...$'
uiViewReturn    DB 'Press any key to return to menu...$'

uiUpdateOpt1        DB '[1] Change status$'
uiUpdateOpt2        DB '[2] Change plate number$'
uiUpdateOpt3        DB '[3] Cancel$'
uiUpdateOpt2Cancel  DB '[2] Cancel$'
uiUpdatePrompt      DB 'Select an option: $'

uiDeleteCancelled   DB 'Delete cancelled. Press any key...$'

; -------------------- Input Buffers --------------------
usernameInput   DB MAX_USERNAME_LEN,0,MAX_USERNAME_LEN DUP(0)
passwordInput   DB MAX_PASSWORD_LEN,0,MAX_PASSWORD_LEN DUP(0)
slotIdBuffer    DB 6,0,6 DUP(0)            ; up to 5 digits
statusBuffer    DB 2,0,2 DUP(0)
plateBuffer     DB MAX_PLATE_LEN,0,MAX_PLATE_LEN DUP(0)
menuBuffer      DB 2,0,2 DUP(0)

digitBuffer     DB 6 DUP(0)                ; for PrintNumber
slotIdTemp      DW 0                      ; holds parsed slot id during creation
slotStatusTemp  DB 0                      ; holds parsed status during creation

; -------------------- User Storage --------------------
userCount       DB 0
userNameLens    DB MAX_USERS DUP(0)
userPassLens    DB MAX_USERS DUP(0)
userNames       DB MAX_USERS*MAX_USERNAME_LEN DUP(0)
userPasses      DB MAX_USERS*MAX_PASSWORD_LEN DUP(0)

; -------------------- Slot Storage --------------------
slotCount       DB 0
slotIds         DW MAX_SLOTS DUP(0)
slotStatus      DB MAX_SLOTS DUP(0)
slotPlateLens   DB MAX_SLOTS DUP(0)
slotPlates      DB MAX_SLOTS*MAX_PLATE_LEN DUP(0)

viewHasRecord   DB 0

.CODE
; -------------------- Utility Routines --------------------
PrintDollarString PROC    ; DS:DX -> '$'-terminated string
    push ax
    push bx
    push dx
    push si

    mov si,dx
    call GetCursorPos
    mov bl,UI_ATTR_NORMAL
    call PrintAtDollarStringAttr

    pop si
    pop dx
    pop bx
    pop ax
    ret
PrintDollarString ENDP

PrintZeroString PROC      ; DS:DX -> zero-terminated string
    push ax
    push bx
    push dx
    push si

    mov si,dx
    call GetCursorPos
    mov bl,UI_ATTR_NORMAL
    call PrintAtZeroStringAttr

    pop si
    pop dx
    pop bx
    pop ax
    ret
PrintZeroString ENDP

PrintNewLine PROC
    push ax
    push dx
    call GetCursorPos
    inc dh
    cmp dh,24
    jbe PNL_Set
    mov dh,24
PNL_Set:
    mov dl,0
    call SetCursorPos
    pop dx
    pop ax
    ret
PrintNewLine ENDP

WaitForKey PROC
    mov ah,08h
    int 21h
    ret
WaitForKey ENDP

ClearScreen PROC
    mov ax,0600h
    mov bh,07h
    mov cx,0000h
    mov dx,184Fh
    int 10h
    mov ah,02h
    mov bh,0
    mov dh,0
    mov dl,0
    int 10h
    ret
ClearScreen ENDP

; -------------------- BIOS UI Routines --------------------
; These helpers use BIOS INT 10h so we can control color + layout.

SetCursorPos PROC          ; DH=row, DL=col
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov ah,02h
    mov bh,0
    int 10h
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
SetCursorPos ENDP

GetCursorPos PROC          ; returns DH=row, DL=col
    push ax
    push bx
    push cx
    push si
    push di
    push bp
    mov ah,03h
    mov bh,0
    int 10h
    pop bp
    pop di
    pop si
    pop cx
    pop bx
    pop ax
    ret
GetCursorPos ENDP

ClearScreenAttr PROC       ; BL=attribute (bg<<4 | fg)
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov ax,0600h
    mov bh,bl
    mov cx,0000h
    mov dx,184Fh
    int 10h
    mov ah,02h
    mov bh,0
    mov dh,0
    mov dl,0
    int 10h
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ClearScreenAttr ENDP

WriteCharAttr PROC         ; AL=char, BL=attribute
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov ah,09h
    mov bh,0
    mov cx,1
    int 10h
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WriteCharAttr ENDP

WriteCharAttrN PROC        ; AL=char, BL=attribute, CX=count
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov ah,09h
    mov bh,0
    int 10h
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WriteCharAttrN ENDP

WriteBufAttrAtCursor PROC  ; DS:SI -> buffer, CX=length, BL=attribute
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    call GetCursorPos

    push ds
    pop es
    mov bp,si

    mov ax,1301h           ; AH=13h write string, AL=01h update cursor
    mov bh,0
    int 10h

    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
WriteBufAttrAtCursor ENDP

StrLenDollar PROC          ; DS:SI -> '$' string, returns CX length (ignores CR/LF)
    push ax
    push si
    xor cx,cx
SLD_Loop:
    lodsb
    cmp al,'$'
    je SLD_Done
    cmp al,0Dh
    je SLD_Loop
    cmp al,0Ah
    je SLD_Loop
    inc cx
    jmp SLD_Loop
SLD_Done:
    pop si
    pop ax
    ret
StrLenDollar ENDP

PrintAtDollarStringAttr PROC ; DS:SI -> '$' string, DH=row, DL=col, BL=attribute
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov [uiIndentCol],dl

    ; ensure ES = DS for BIOS "write string" call
    push ds
    pop es

    mov bp,si              ; BP = start of current line segment
    xor cx,cx              ; CX = length of current segment

PAD_Scan:
    lodsb
    cmp al,'$'
    je PAD_FlushAndDone
    cmp al,0Dh
    je PAD_CR
    cmp al,0Ah
    je PAD_LF
    inc cx
    jmp PAD_Scan

PAD_CR:
    call PAD_FlushSegment
    mov dl,[uiIndentCol]
    call SetCursorPos
    mov bp,si
    xor cx,cx
    jmp PAD_Scan

PAD_LF:
    call PAD_FlushSegment
    inc dh
    mov dl,[uiIndentCol]
    call SetCursorPos
    mov bp,si
    xor cx,cx
    jmp PAD_Scan

PAD_FlushAndDone:
    call PAD_FlushSegment
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

; Print ES:BP segment length CX at DH:DL using attribute in BL.
PAD_FlushSegment:
    or cx,cx
    jz PAD_FlushRet
    push ax
    push bx
    push cx
    push dx
    mov ax,1301h           ; AH=13h write string, AL=01h update cursor
    mov bh,0
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
PAD_FlushRet:
    ret
PrintAtDollarStringAttr ENDP

PrintAtZeroStringAttr PROC ; DS:SI -> zero-terminated string, DH=row, DL=col, BL=attribute
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    push es

    mov [uiIndentCol],dl
    call SetCursorPos

    push ds
    pop es

    mov bp,si              ; BP = start of current line segment
    xor cx,cx              ; CX = length of current segment

PAZ_Scan:
    lodsb
    cmp al,0
    je PAZ_FlushAndDone
    cmp al,0Dh
    je PAZ_CR
    cmp al,0Ah
    je PAZ_LF
    inc cx
    jmp PAZ_Scan

PAZ_CR:
    call PAZ_FlushSegment
    mov dl,[uiIndentCol]
    call SetCursorPos
    mov bp,si
    xor cx,cx
    jmp PAZ_Scan

PAZ_LF:
    call PAZ_FlushSegment
    inc dh
    mov dl,[uiIndentCol]
    call SetCursorPos
    mov bp,si
    xor cx,cx
    jmp PAZ_Scan

PAZ_FlushAndDone:
    call PAZ_FlushSegment
    pop es
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret

PAZ_FlushSegment:
    or cx,cx
    jz PAZ_FlushRet
    push ax
    push bx
    push cx
    push dx
    mov ax,1301h
    mov bh,0
    int 10h
    pop dx
    pop cx
    pop bx
    pop ax
PAZ_FlushRet:
    ret
PrintAtZeroStringAttr ENDP

PrintCenteredDollarStringAttr PROC ; DS:SI -> '$' string, DH=row, BL=attribute
    push ax
    push cx
    push dx
    call StrLenDollar
    mov ax,76               ; inner width (cols 2..77)
    sub ax,cx
    shr ax,1
    add ax,2                ; inner left
    mov dl,al
    call PrintAtDollarStringAttr
    pop dx
    pop cx
    pop ax
    ret
PrintCenteredDollarStringAttr ENDP

DrawMainFrame PROC         ; BL=attribute
    push ax
    push bx
    push cx
    push dx

    ; Top border (row 1, col 1..78)
    mov dh,1
    mov dl,1
    call SetCursorPos
    mov al,201              ; ╔
    call WriteCharAttr
    mov dl,2
    call SetCursorPos
    mov al,205              ; ═
    mov cx,76
    call WriteCharAttrN
    mov dl,78
    call SetCursorPos
    mov al,187              ; ╗
    call WriteCharAttr

    ; Sides (rows 2..22)
    mov dh,2
DMF_SideLoop:
    cmp dh,23
    je DMF_Bottom
    mov dl,1
    call SetCursorPos
    mov al,186              ; ║
    call WriteCharAttr
    mov dl,78
    call SetCursorPos
    mov al,186              ; ║
    call WriteCharAttr
    inc dh
    jmp DMF_SideLoop

DMF_Bottom:
    ; Bottom border (row 23, col 1..78)
    mov dh,23
    mov dl,1
    call SetCursorPos
    mov al,200              ; ╚
    call WriteCharAttr
    mov dl,2
    call SetCursorPos
    mov al,205              ; ═
    mov cx,76
    call WriteCharAttrN
    mov dl,78
    call SetCursorPos
    mov al,188              ; ╝
    call WriteCharAttr

    pop dx
    pop cx
    pop bx
    pop ax
    ret
DrawMainFrame ENDP

UiPrepareScreen PROC
    push bx
    mov bl,UI_ATTR_NORMAL
    call ClearScreenAttr
    mov bl,UI_ATTR_BORDER
    call DrawMainFrame
    pop bx
    ret
UiPrepareScreen ENDP

ReadLine PROC             ; DX = buffer
    push ax
    push bx
    push cx
    push dx

    mov ah,0Ah
    int 21h

    ; zero-terminate input
    mov bx,dx
    mov cl,[bx+1]
    mov ch,0
    add bx,2
    add bx,cx
    mov byte ptr [bx],0

    pop dx
    pop cx
    pop bx
    pop ax
    ret
ReadLine ENDP


; Parse numeric input from buffered line input
; IN:  DX -> buffer (0Ah format)
; OUT: AX = value, CF = 0 success, CF = 1 invalid
ParseNumber PROC
    push bx
    push cx
    push dx
    push si
    mov si,dx
    mov cl,[si+1]         ; length entered
    cmp cl,0
    je ParseNumError
    mov ax,0
    add si,2
ParseNumLoop:
    cmp cl,0
    je ParseNumOk
    mov bl,[si]
    cmp bl,'0'
    jb ParseNumError
    cmp bl,'9'
    ja ParseNumError
    sub bl,'0'
    mov bh,0              ; digit now in BX (low byte)

    ; AX = AX * 10 using shifts (old*2 + old*8)
    mov dx,ax
    shl ax,1              ; AX = old*2
    shl dx,3              ; DX = old*8
    add ax,dx             ; AX = old*10
    add ax,bx             ; add digit
    inc si
    dec cl
    jmp ParseNumLoop
ParseNumOk:
    clc
    jmp ParseNumExit
ParseNumError:
    stc
ParseNumExit:
    pop si
    pop dx
    pop cx
    pop bx
    ret
ParseNumber ENDP

; Print AX as unsigned decimal
PrintNumber PROC
    push ax
    push bx
    push cx
    push dx
    push si
    mov bx,10
    mov si,OFFSET digitBuffer+5
    mov cx,0
    cmp ax,0
    jne PNLoop
    mov byte ptr [si],'0'
    mov cx,1
    jmp PNPrintBuf
PNLoop:
    xor dx,dx
    div bx              ; AX = AX/10, DX = remainder
    add dl,'0'
    mov [si],dl
    dec si
    inc cx
    cmp ax,0
    jne PNLoop
    inc si              ; move to first digit
PNPrintBuf:
    mov bl,UI_ATTR_NORMAL
    call WriteBufAttrAtCursor
PNDone:
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
PrintNumber ENDP

; Compare buffered input (DX) with stored string (SI, length in BL)
; Returns AL=1 if equal, AL=0 otherwise. Destroys CX.
CompareBufferToStored PROC
    push dx
    push si
    mov di,dx
    mov al,[di+1]
    cmp al,bl
    jne CmpNotEqual
    mov cl,bl
    mov ch,0
    add di,2
    cmp cx,0
    je CmpEqual
CmpLoop:
    mov ah,[si]
    mov dl,[di]
    cmp ah,dl
    jne CmpNotEqual
    inc si
    inc di
    loop CmpLoop
CmpEqual:
    mov al,1
    jmp CmpExit
CmpNotEqual:
    mov al,0
CmpExit:
    pop si
    pop dx
    ret
CompareBufferToStored ENDP

; Copy buffered input (DX) into destination DI, length from [DX+1]
CopyBufferToDest PROC
    push ax
    push cx
    push si
    mov si,dx
    mov cl,[si+1]
    add si,2
    mov ch,0
    rep movsb
    pop si
    pop cx
    pop ax
    ret
CopyBufferToDest ENDP

; Convert character in AL to uppercase (ASCII letters only)
ToUpper PROC
    cmp al,'a'
    jb UpperDone
    cmp al,'z'
    ja UpperDone
    sub al,20h
UpperDone:
    ret
ToUpper ENDP
FlushKeyboard PROC
    mov ah,0Ch
    mov al,00h              ; flush typeahead only
    int 21h
    ret
FlushKeyboard ENDP
; Find user index by username buffer (DX). AL=1 if found, BL=index; AL=0 if not found.
FindUserByName PROC
    push cx
    push dx
    push si
    push di
    mov cl,userCount
    mov ch,0
    mov di,0                  ; DI = index
    cmp cx,0
    je FUserNotFound
FUserLoop:
    ; compute stored username pointer: index * 16
    mov ax,di
    shl ax,4
    mov si,OFFSET userNames
    add si,ax

    ; load stored length
    mov bl,[userNameLens+di]

    ; CompareBufferToStored destroys CX and DI
    push cx
    push di
    call CompareBufferToStored
    pop di
    pop cx

    cmp al,1
    je FUserFound

    inc di
    dec cx
    jnz FUserLoop
FUserNotFound:
    mov al,0
    jmp FUserExit
FUserFound:
    mov bx,di                 ; return index in BL
    mov al,1
FUserExit:
    pop di
    pop si
    pop dx
    pop cx
    ret
FindUserByName ENDP

; Find slot index by slot id in AX. CF=0 if found (BL=index), CF=1 if not found.
FindSlotById PROC
    push ax
    push cx
    push dx
    push si
    mov cl,slotCount
    mov ch,0
    cmp cl,0
    je SlotNotFound
    mov si,OFFSET slotIds
    mov bl,0
SlotSearchLoop:
    cmp ax,[si]
    je SlotFound
    add si,2
    inc bl
    loop SlotSearchLoop
SlotNotFound:
    stc
    jmp SlotSearchExit
SlotFound:
    clc
SlotSearchExit:
    pop si
    pop dx
    pop cx
    pop ax
    ret
FindSlotById ENDP

; Print zero-terminated message then wait for any key
ShowMsgAndPause PROC
    push ax
    push dx
    call PrintZeroString
    call FlushKeyboard
    call WaitForKey
    pop dx
    pop ax
    ret
ShowMsgAndPause ENDP

; Print status text based on AL (0=FREE,1=OCCUPIED,2=DELETED)
PrintStatusText PROC
    cmp al,STATUS_FREE
    je PST_Free
    cmp al,STATUS_OCCUPIED
    je PST_Occ
    ; default to DELETED (won't normally print)
    ret
PST_Free:
    mov dx,OFFSET statusFreeStr
    call PrintDollarString
    ret
PST_Occ:
    mov dx,OFFSET statusOccStr
    call PrintDollarString
    ret
PrintStatusText ENDP

; -------------------- Screen + Auth --------------------
OpeningScreen PROC
    mov bl,UI_ATTR_NORMAL
    call ClearScreenAttr
    mov bl,UI_ATTR_BORDER
    call DrawMainFrame

    mov bl,UI_ATTR_TITLE
    mov dh,4
    mov si,OFFSET uiOpenTitle
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_NORMAL
    mov dh,6
    mov si,OFFSET uiOpenSubtitle
    call PrintCenteredDollarStringAttr

    mov dh,9
    mov si,OFFSET uiOpenByLine
    call PrintCenteredDollarStringAttr

    mov dh,10
    mov si,OFFSET uiOpenDateLine
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_PROMPT
    mov dh,20
    mov si,OFFSET uiOpenContinue
    call PrintCenteredDollarStringAttr

    call WaitForKey
    ret
OpeningScreen ENDP

RegisterUser PROC
    push ax
    push bx
    push dx
    push si
    push di
    cmp userCount,MAX_USERS
    jb RegStart
    jmp RegFull
RegStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiRegisterTitle
    call PrintCenteredDollarStringAttr

    call FlushKeyboard
    mov bl,UI_ATTR_PROMPT
    mov dh,7
    mov dl,6
    mov si,OFFSET loginUserPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET usernameInput
    call ReadLine
    mov al,[usernameInput+1]
    cmp al,0
    jne RegUserOk1
    jmp RegInvalid
RegUserOk1:

    ; Check duplicate username
    mov dx,OFFSET usernameInput
    call FindUserByName
    cmp al,1
    jne RegUserNotDup
    jmp RegExists
RegUserNotDup:
    mov bl,UI_ATTR_PROMPT
    mov dh,9
    mov dl,6
    mov si,OFFSET loginPassPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET passwordInput
    call ReadLine
    mov al,[passwordInput+1]
    cmp al,0
    jne RegPassOk
    jmp RegInvalid
RegPassOk:

    ; store user
    mov bl,userCount
    mov bh,0

    ; store username length
    mov al,[usernameInput+1]
    mov [userNameLens+bx],al
    ; compute username offset
    mov ax,bx
    mov dl,MAX_USERNAME_LEN
    mul dl
    mov di,OFFSET userNames
    add di,ax
    mov dx,OFFSET usernameInput
    call CopyBufferToDest

    ; store password length
    mov ax,bx
    mov dl,MAX_PASSWORD_LEN
    mul dl
    mov di,OFFSET userPasses
    add di,ax
    mov al,[passwordInput+1]
    mov [userPassLens+bx],al
    mov dx,OFFSET passwordInput
    call CopyBufferToDest

    inc userCount
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET registerOkMsg
    call ShowMsgAndPause
    jmp RegExit

RegInvalid:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp RegStart
RegExists:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET userExistsMsg
    call ShowMsgAndPause
    jmp RegStart
RegFull:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiRegisterTitle
    call PrintCenteredDollarStringAttr
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET userLimitMsg
    call ShowMsgAndPause
RegExit:
    pop di
    pop si
    pop dx
    pop bx
    pop ax
    ret
RegisterUser ENDP

; Returns AL=1 if login success, AL=0 otherwise
LoginUser PROC
    push bx
    push dx
    push si
    push di
    cmp userCount,0
    jne LoginStart
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiLoginTitle
    call PrintCenteredDollarStringAttr
    mov dh,8
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET noUsersMsg
    call ShowMsgAndPause
    mov al,0
    jmp LoginExit
LoginStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiLoginTitle
    call PrintCenteredDollarStringAttr

    call FlushKeyboard
    mov bl,UI_ATTR_PROMPT
    mov dh,7
    mov dl,6
    mov si,OFFSET loginUserPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET usernameInput
    call ReadLine
    mov al,[usernameInput+1]
    cmp al,0
    je LoginFail

    mov bl,UI_ATTR_PROMPT
    mov dh,9
    mov dl,6
    mov si,OFFSET loginPassPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET passwordInput
    call ReadLine
    mov al,[passwordInput+1]
    cmp al,0
    je LoginFail

    mov dx,OFFSET usernameInput
    call FindUserByName
    cmp al,1
    jne LoginFail

    ; BL = user index
    mov di,bx
    mov ax,di
    mov dl,MAX_PASSWORD_LEN
    mul dl
    mov si,OFFSET userPasses
    add si,ax
    mov bx,di
    mov bl,[userPassLens+bx]
    mov dx,OFFSET passwordInput
    call CompareBufferToStored
    cmp al,1
    jne LoginFail

    mov al,1
    jmp LoginExit

LoginFail:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET loginFailMsg
    call ShowMsgAndPause
    mov al,0
    jmp LoginStart

LoginExit:
    pop di
    pop si
    pop dx
    pop bx
    ret
LoginUser ENDP

; Authentication menu: AL=1 login success, AL=0 exit
AuthMenu PROC
AuthLoop:
    mov bl,UI_ATTR_NORMAL
    call ClearScreenAttr
    mov bl,UI_ATTR_BORDER
    call DrawMainFrame

    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiAuthHeader
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_NORMAL
    mov dh,7
    mov dl,6
    mov si,OFFSET uiAuthOpt1
    call PrintAtDollarStringAttr
    mov dh,8
    mov dl,6
    mov si,OFFSET uiAuthOpt2
    call PrintAtDollarStringAttr
    mov dh,9
    mov dl,6
    mov si,OFFSET uiAuthOpt3
    call PrintAtDollarStringAttr

    mov bl,UI_ATTR_PROMPT
    mov dh,12
    mov dl,6
    mov si,OFFSET uiAuthPrompt
    call PrintAtDollarStringAttr

    call FlushKeyboard
    mov ah,08h
    int 21h
    mov bl,UI_ATTR_PROMPT
    call WriteCharAttr
    cmp al,'1'
    je AuthDoLogin
    cmp al,'2'
    je AuthDoRegister
    cmp al,'3'
    je AuthExit

    mov bl,UI_ATTR_ERROR
    mov dh,21
    mov dl,6
    mov si,OFFSET uiInvalidChoice
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
    jmp AuthLoop
AuthDoLogin:
    call FlushKeyboard   ; <<< REQUIRED
    call LoginUser
    cmp al,1
    je AuthSuccess
    jmp AuthLoop
AuthDoRegister:
    call FlushKeyboard
    call RegisterUser
    jmp AuthLoop
AuthExit:
    mov al,0
    ret
AuthSuccess:
    mov al,1
    ret
AuthMenu ENDP

; -------------------- Slot CRUD --------------------
CreateSlot PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    cmp slotCount,MAX_SLOTS
    jb CSStart
    jmp CSFull
CSStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiCreateTitle
    call PrintCenteredDollarStringAttr

    call FlushKeyboard
    mov bl,UI_ATTR_PROMPT
    mov dh,7
    mov dl,6
    mov si,OFFSET slotIdPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    mov dx,OFFSET slotIdBuffer
    call ParseNumber
    jnc CSIdOk
    jmp CSInvalid
CSIdOk:

    ; check duplicate id
    call FindSlotById
    jc CSNoDup
    jmp CSDuplicate
CSNoDup:
    mov slotIdTemp,ax        ; preserve slot id safely

    mov bl,UI_ATTR_PROMPT
    mov dh,9
    mov dl,6
    mov si,OFFSET statusPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET statusBuffer
    call ReadLine
    mov al,[statusBuffer+1]
    cmp al,0
    jne CSStatusOk
    jmp CSInvalid
CSStatusOk:
    mov al,[statusBuffer+2]
    call ToUpper
    cmp al,'F'
    je CSSetFree
    cmp al,'O'
    je CSSetOcc
    jmp CSInvalid

CSSetFree:
    mov ah,STATUS_FREE
    mov slotStatusTemp,ah
    mov byte ptr [plateBuffer+1],0
    jmp CSSave
CSSetOcc:
    mov bl,UI_ATTR_PROMPT
    mov dh,11
    mov dl,6
    mov si,OFFSET platePrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET plateBuffer
    call ReadLine
    mov al,[plateBuffer+1]
    cmp al,0
    jne CSPlateOk
    jmp CSInvalid
CSPlateOk:
    mov ah,STATUS_OCCUPIED
    mov slotStatusTemp,ah

CSSave:
    mov bl,slotCount
    mov bh,0                 ; BX = index

    ; save slot id
    mov di,OFFSET slotIds
    mov dx,bx
    shl dx,1
    add di,dx
    mov ax,slotIdTemp
    mov [di],ax

    ; save status (cached in slotStatusTemp)
    mov di,OFFSET slotStatus
    add di,bx
    mov al,slotStatusTemp
    mov [di],al

    ; save plate length
    mov di,OFFSET slotPlateLens
    add di,bx
    mov al,slotStatusTemp
    cmp al,STATUS_OCCUPIED
    jne CSSetEmptyPlate
    mov al,[plateBuffer+1]
    mov [di],al
    ; copy plate data
    mov ax,bx
    mov bx,MAX_PLATE_LEN
    mul bx
    mov di,OFFSET slotPlates
    add di,ax
    mov dx,OFFSET plateBuffer
    call CopyBufferToDest
    jmp CSPlateDone
CSSetEmptyPlate:
    mov byte ptr [di],0
    mov ax,bx
    mov bx,MAX_PLATE_LEN
    mul bx
    mov di,OFFSET slotPlates
    add di,ax
    mov byte ptr [di],0
CSPlateDone:
    inc slotCount
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET slotCreateOk
    call ShowMsgAndPause
    jmp CSDone

CSDuplicate:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET slotExistsMsg
    call ShowMsgAndPause
    jmp CSStart
CSInvalid:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp CSStart
CSFull:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiCreateTitle
    call PrintCenteredDollarStringAttr
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET slotFullMsg
    call ShowMsgAndPause
CSDone:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
CreateSlot ENDP

ViewSlots PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
    mov byte ptr viewHasRecord,0
    mov di,0                  ; DI = slot index (persists across pages)

VSPageStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiViewTitle
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_TITLE
    mov dh,5
    mov dl,6
    mov si,OFFSET tableHeader
    call PrintAtDollarStringAttr

    mov cx,MAX_SLOTS           ; scan full capacity so no record is missed

VSPrintPage:
    xor bp,bp                 ; BP = records printed on this page

VSLoop:
    cmp di,cx
    jb VSLoopBody
    jmp VSAfterPage

VSLoopBody:
    ; load slot id for this index
    mov ax,di
    shl ax,1
    mov si,OFFSET slotIds
    add si,ax
    mov ax,[si]
    cmp ax,0
    jne VSCheckStatus
    jmp VSNextIndex           ; empty slot

VSCheckStatus:
    push ax                   ; preserve slot id without clobbering DH
    mov bx,di
    mov al,[slotStatus+bx]
    cmp al,STATUS_DELETED
    jne VSRecordActive
    pop ax
    jmp VSNextIndex

VSRecordActive:
    pop ax                    ; restore slot id for printing
    mov byte ptr viewHasRecord,1

    push ax                   ; save slot id while computing row
    mov ax,bp                 ; AX = records printed on this page
    add al,7                  ; row = 7 + BP
    mov dh,al
    pop ax                    ; restore slot id
    mov dl,6
    call SetCursorPos

    ; slot id
    call PrintNumber

    mov dx,OFFSET pipeSep
    call PrintDollarString

    ; status
    mov al,[slotStatus+bx]
    call PrintStatusText

    mov dx,OFFSET pipeSep
    call PrintDollarString

    ; plate
    mov al,[slotStatus+bx]
    cmp al,STATUS_OCCUPIED
    jne VSDash
    mov al,[slotPlateLens+bx]
    cmp al,0
    je VSDash

    push dx                    ; keep DH/DL (cursor row/col) intact
    mov ax,di
    mov si,MAX_PLATE_LEN
    mul si
    mov si,OFFSET slotPlates
    add si,ax
    push cx
    mov cl,[slotPlateLens+bx]
    mov ch,0
    mov bl,UI_ATTR_NORMAL
    call WriteBufAttrAtCursor
    pop cx
    pop dx                     ; restore cursor row in DH
    jmp VSAfterPlate

VSDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
VSAfterPlate:

    inc bp
    inc di
    cmp bp,14
    jae VSAfterPage
    jmp VSLoop

VSNextIndex:
    inc di
    jmp VSLoop

VSAfterPage:
    cmp byte ptr viewHasRecord,0
    jne VSCheckMore
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET noSlotsMsg
    call ShowMsgAndPause
    jmp VSDone

VSCheckMore:
    ; Scan remaining indices for any active record
    mov bx,di
VSScanMore:
    cmp bx,MAX_SLOTS
    jae VSNoMore
    mov ax,bx
    shl ax,1
    mov si,OFFSET slotIds
    add si,ax
    mov ax,[si]
    cmp ax,0
    jne VSScanStatus
    jmp VSScanNext
VSScanStatus:
    mov al,[slotStatus+bx]
    cmp al,STATUS_DELETED
    jne VSHasMore
VSScanNext:
    inc bx
    jmp VSScanMore

VSHasMore:
    mov bl,UI_ATTR_PROMPT
    mov dh,21
    mov dl,6
    mov si,OFFSET uiViewNextPage
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
    jmp VSPageStart

VSNoMore:
    mov bl,UI_ATTR_PROMPT
    mov dh,21
    mov dl,6
    mov si,OFFSET uiViewReturn
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
VSDone:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
ViewSlots ENDP

UpdateSlot PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
USStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiUpdateTitle
    call PrintCenteredDollarStringAttr

    call FlushKeyboard
    mov bl,UI_ATTR_PROMPT
    mov dh,7
    mov dl,6
    mov si,OFFSET slotIdPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    mov dx,OFFSET slotIdBuffer
    call ParseNumber
    jnc USIdOk
    jmp USInvalid
USIdOk:
    call FindSlotById
    jnc USFound
    jmp USNotFound
USFound:
    xor bh,bh
    mov di,bx
    mov al,[slotStatus+di]
    cmp al,STATUS_DELETED
    jne USRecOk
    jmp USNotFound
USRecOk:
    ; Slot ID
    mov bl,UI_ATTR_NORMAL
    mov dh,9
    mov dl,6
    mov si,OFFSET slotIdLabel
    call PrintAtDollarStringAttr
    mov ax,di
    shl ax,1
    mov si,OFFSET slotIds
    add si,ax
    mov ax,[si]
    call PrintNumber

    ; Status
    mov bl,UI_ATTR_NORMAL
    mov dh,10
    mov dl,6
    mov si,OFFSET statusLabel
    call PrintAtDollarStringAttr
    mov al,[slotStatus+di]
    call PrintStatusText

    ; Plate
    mov bl,UI_ATTR_NORMAL
    mov dh,11
    mov dl,6
    mov si,OFFSET plateLabel
    call PrintAtDollarStringAttr
    mov al,[slotStatus+di]
    cmp al,STATUS_OCCUPIED
    jne USShowDash
    mov al,[slotPlateLens+di]
    cmp al,0
    je USShowDash
    mov ax,di
    mov si,MAX_PLATE_LEN
    mul si
    mov si,OFFSET slotPlates
    add si,ax
    push cx
    mov cl,[slotPlateLens+di]
    mov ch,0
    mov bl,UI_ATTR_NORMAL
    call WriteBufAttrAtCursor
    pop cx
    jmp USAfterPlateShow
USShowDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
USAfterPlateShow:

    ; Options
    mov bl,UI_ATTR_NORMAL
    mov dh,14
    mov dl,6
    mov si,OFFSET uiUpdateOpt1
    call PrintAtDollarStringAttr
    mov al,[slotStatus+di]
    cmp al,STATUS_OCCUPIED
    jne USOptsFree
    mov dh,15
    mov dl,6
    mov si,OFFSET uiUpdateOpt2
    call PrintAtDollarStringAttr
    mov dh,16
    mov dl,6
    mov si,OFFSET uiUpdateOpt3
    call PrintAtDollarStringAttr
    jmp USOptsPrompt
USOptsFree:
    mov dh,15
    mov dl,6
    mov si,OFFSET uiUpdateOpt2Cancel
    call PrintAtDollarStringAttr
USOptsPrompt:
    mov bl,UI_ATTR_PROMPT
    mov dh,18
    mov dl,6
    mov si,OFFSET uiUpdatePrompt
    call PrintAtDollarStringAttr

    call FlushKeyboard
    mov ah,08h
    int 21h
    mov [digitBuffer],al
    mov si,OFFSET digitBuffer
    mov cx,1
    mov bl,UI_ATTR_PROMPT
    call WriteBufAttrAtCursor

    cmp al,'1'
    je USChangeStatus
    cmp al,'2'
    je USChoice2
    cmp al,'3'
    je USCancel
    jmp USBadMenu

USChoice2:
    mov al,[slotStatus+di]
    cmp al,STATUS_OCCUPIED
    jne USCancel
    jmp USChangePlate

USCancel:
    jmp USDone

USBadMenu:
    mov dh,19
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp USStart

USChangeStatus:
    mov bl,UI_ATTR_PROMPT
    mov dh,20
    mov dl,6
    mov si,OFFSET statusPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET statusBuffer
    call ReadLine
    mov al,[statusBuffer+1]
    cmp al,0
    jne USStatusOk
    jmp USInvalid
USStatusOk:
    mov al,[statusBuffer+2]
    call ToUpper
    cmp al,'F'
    je USSetFree
    cmp al,'O'
    je USSetOcc
    jmp USInvalid
USSetFree:
    mov al,STATUS_FREE
    jmp USApplyStatus
USSetOcc:
    mov al,STATUS_OCCUPIED
USApplyStatus:
    mov [slotStatus+di],al
    cmp al,STATUS_OCCUPIED
    jne USClearPlate
    mov bl,UI_ATTR_PROMPT
    mov dh,21
    mov dl,6
    mov si,OFFSET platePrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET plateBuffer
    call ReadLine
    mov al,[plateBuffer+1]
    cmp al,0
    je USInvalid
    jmp USCopyPlate
USClearPlate:
    mov byte ptr [slotPlateLens+di],0
    mov ax,di
    mov si,MAX_PLATE_LEN
    mul si
    mov si,OFFSET slotPlates
    add si,ax
    mov byte ptr [si],0
    jmp USUpdateDone

USChangePlate:
    mov bl,UI_ATTR_PROMPT
    mov dh,20
    mov dl,6
    mov si,OFFSET platePrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET plateBuffer
    call ReadLine
    mov al,[plateBuffer+1]
    cmp al,0
    je USInvalid
USCopyPlate:
    mov al,[plateBuffer+1]
    mov [slotPlateLens+di],al
    mov ax,di
    mov si,MAX_PLATE_LEN
    mul si
    mov di,OFFSET slotPlates
    add di,ax
    mov dx,OFFSET plateBuffer
    call CopyBufferToDest

USUpdateDone:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET updateOkMsg
    call ShowMsgAndPause
    jmp USDone

USInvalid:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp USStart
USNotFound:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET notFoundMsg
    call ShowMsgAndPause
USDone:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
UpdateSlot ENDP

DeleteSlot PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push bp
DSStart:
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiDeleteTitle
    call PrintCenteredDollarStringAttr

    call FlushKeyboard
    mov bl,UI_ATTR_PROMPT
    mov dh,7
    mov dl,6
    mov si,OFFSET slotIdPrompt
    call PrintAtDollarStringAttr
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    mov dx,OFFSET slotIdBuffer
    call ParseNumber
    jnc DSIdOk
    jmp DSInvalid
DSIdOk:
    call FindSlotById
    jnc DSFound
    jmp DSNotFound
DSFound:
    xor bh,bh
    mov di,bx
    mov al,[slotStatus+di]
    cmp al,STATUS_DELETED
    jne DSFoundOk
    jmp DSNotFound
DSFoundOk:
    ; Slot ID
    mov bl,UI_ATTR_NORMAL
    mov dh,9
    mov dl,6
    mov si,OFFSET slotIdLabel
    call PrintAtDollarStringAttr
    mov ax,di
    shl ax,1
    mov si,OFFSET slotIds
    add si,ax
    mov ax,[si]
    call PrintNumber

    ; Status
    mov bl,UI_ATTR_NORMAL
    mov dh,10
    mov dl,6
    mov si,OFFSET statusLabel
    call PrintAtDollarStringAttr
    mov al,[slotStatus+di]
    call PrintStatusText

    ; Plate
    mov bl,UI_ATTR_NORMAL
    mov dh,11
    mov dl,6
    mov si,OFFSET plateLabel
    call PrintAtDollarStringAttr
    mov al,[slotStatus+di]
    cmp al,STATUS_OCCUPIED
    jne DSDash
    mov al,[slotPlateLens+di]
    cmp al,0
    je DSDash
    mov ax,di
    mov si,MAX_PLATE_LEN
    mul si
    mov si,OFFSET slotPlates
    add si,ax
    push cx
    mov cl,[slotPlateLens+di]
    mov ch,0
    mov bl,UI_ATTR_NORMAL
    call WriteBufAttrAtCursor
    pop cx
    jmp DSAfterPlateShow
DSDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
DSAfterPlateShow:

    mov bl,UI_ATTR_PROMPT
    mov dh,14
    mov dl,6
    mov si,OFFSET deleteConfirm
    call PrintAtDollarStringAttr

    call FlushKeyboard
    mov ah,08h
    int 21h
    mov [digitBuffer],al
    mov si,OFFSET digitBuffer
    mov cx,1
    mov bl,UI_ATTR_PROMPT
    call WriteBufAttrAtCursor

    call ToUpper
    cmp al,'Y'
    je DSDoDelete

    mov bl,UI_ATTR_PROMPT
    mov dh,18
    mov dl,6
    mov si,OFFSET uiDeleteCancelled
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
    jmp DSDone

DSDoDelete:
    mov byte ptr [slotStatus+di],STATUS_DELETED
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET deleteOkMsg
    call ShowMsgAndPause
    jmp DSDone

DSInvalid:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp DSStart
DSNotFound:
    mov dh,18
    mov dl,6
    call SetCursorPos
    mov dx,OFFSET notFoundMsg
    call ShowMsgAndPause
DSDone:
    pop bp
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
DeleteSlot ENDP

; Main menu loop. Returns on logout; exits program on choice 6.
MainMenu PROC
MainLoop:
    mov bl,UI_ATTR_NORMAL
    call ClearScreenAttr
    mov bl,UI_ATTR_BORDER
    call DrawMainFrame

    mov bl,UI_ATTR_TITLE
    mov dh,3
    mov si,OFFSET uiMainHeader
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_NORMAL
    mov dh,7
    mov dl,6
    mov si,OFFSET uiMainOpt1
    call PrintAtDollarStringAttr
    mov dh,8
    mov dl,6
    mov si,OFFSET uiMainOpt2
    call PrintAtDollarStringAttr
    mov dh,9
    mov dl,6
    mov si,OFFSET uiMainOpt3
    call PrintAtDollarStringAttr
    mov dh,10
    mov dl,6
    mov si,OFFSET uiMainOpt4
    call PrintAtDollarStringAttr
    mov dh,11
    mov dl,6
    mov si,OFFSET uiMainOpt5
    call PrintAtDollarStringAttr
    mov dh,12
    mov dl,6
    mov si,OFFSET uiMainOpt6
    call PrintAtDollarStringAttr

    mov bl,UI_ATTR_PROMPT
    mov dh,15
    mov dl,6
    mov si,OFFSET uiMainPrompt
    call PrintAtDollarStringAttr

    call FlushKeyboard
    mov ah,08h
    int 21h
    mov bl,UI_ATTR_PROMPT
    call WriteCharAttr
    cmp al,'1'
    je MMCreate
    cmp al,'2'
    je MMView
    cmp al,'3'
    je MMUpdate
    cmp al,'4'
    je MMDelete
    cmp al,'5'
    je MMLogout
    cmp al,'6'
    je MMExit

    mov bl,UI_ATTR_ERROR
    mov dh,21
    mov dl,6
    mov si,OFFSET uiInvalidChoice
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
    jmp MainLoop
MMCreate:
    call CreateSlot
    jmp MainLoop
MMView:
    call ViewSlots
    jmp MainLoop
MMUpdate:
    call UpdateSlot
    jmp MainLoop
MMDelete:
    call DeleteSlot
    jmp MainLoop
MMLogout:
    mov bl,UI_ATTR_PROMPT
    mov dh,21
    mov dl,6
    mov si,OFFSET logoutMsg
    call PrintAtDollarStringAttr
    call FlushKeyboard
    call WaitForKey
    mov al,0
    ret
MMExit:
    call ExitProgram
MainMenu ENDP

ExitProgram PROC
    call UiPrepareScreen
    mov bl,UI_ATTR_TITLE
    mov dh,5
    mov si,OFFSET uiExitTitle
    call PrintCenteredDollarStringAttr

    mov bl,UI_ATTR_NORMAL
    mov dh,12
    mov si,OFFSET exitMsg
    call PrintCenteredDollarStringAttr
    mov ax,4C00h
    int 21h
ExitProgram ENDP

; -------------------- Program Entry --------------------
MAIN PROC
    mov ax,@data
    mov ds,ax
    mov es,ax

    mov ax,0003h
    int 10h

    call OpeningScreen

AuthReturn:
    call AuthMenu
    cmp al,1
    je RunMain
    jmp ProgramExit
RunMain:
    call MainMenu
    cmp al,0
    je AuthReturn
ProgramExit:
    call ExitProgram
MAIN ENDP

END MAIN
