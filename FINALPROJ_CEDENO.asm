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
MAX_SLOTS           EQU 20
MAX_PLATE_LEN       EQU 12

STATUS_FREE         EQU 0
STATUS_OCCUPIED     EQU 1
STATUS_DELETED      EQU 2

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
slotFullMsg     DB 'Storage full. Cannot create more slots.',13,10
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

; -------------------- Input Buffers --------------------
usernameInput   DB MAX_USERNAME_LEN,0,MAX_USERNAME_LEN DUP(0)
passwordInput   DB MAX_PASSWORD_LEN,0,MAX_PASSWORD_LEN DUP(0)
slotIdBuffer    DB 6,0,6 DUP(0)            ; up to 5 digits
statusBuffer    DB 2,0,2 DUP(0)
plateBuffer     DB MAX_PLATE_LEN,0,MAX_PLATE_LEN DUP(0)
menuBuffer      DB 2,0,2 DUP(0)

digitBuffer     DB 6 DUP(0)                ; for PrintNumber

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
    mov ah,09h
    int 21h
    ret
PrintDollarString ENDP

PrintZeroString PROC      ; DS:DX -> zero-terminated string
    push ax
    push dx
    push bx
    push cx
    push si
    mov si,dx
PrintZeroLoop:
    lodsb
    cmp al,0
    je PrintZeroDone
    mov dl,al
    mov ah,02h
    int 21h
    jmp PrintZeroLoop
PrintZeroDone:
    pop si
    pop cx
    pop bx
    pop dx
    pop ax
    ret
PrintZeroString ENDP

PrintNewLine PROC
    push ax
    push dx
    mov dl,0Dh
    mov ah,02h
    int 21h
    mov dl,0Ah
    mov ah,02h
    int 21h
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
    mov dl,'0'
    mov ah,02h
    int 21h
    jmp PNDone
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
PNPrint:
    cmp cx,0
    je PNDone
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    loop PNPrint
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
    call ClearScreen
    mov dx,OFFSET openingScreenText
    call PrintDollarString
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
    call ClearScreen
    mov dx,OFFSET registerHeader
    call PrintDollarString
    call PrintNewLine
    mov dx,OFFSET loginUserPrompt
    call PrintDollarString
    mov dx,OFFSET usernameInput
    call ReadLine
    call PrintNewLine
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

    mov dx,OFFSET loginPassPrompt
    call PrintDollarString
    mov dx,OFFSET passwordInput
    call ReadLine
    call PrintNewLine
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
    mov dx,OFFSET registerOkMsg
    call ShowMsgAndPause
    jmp RegExit

RegInvalid:
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp RegStart
RegExists:
    mov dx,OFFSET userExistsMsg
    call ShowMsgAndPause
    jmp RegStart
RegFull:
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
    call PrintNewLine            ; move off menu input line when no users exist
    mov dx,OFFSET noUsersMsg
    call ShowMsgAndPause
    mov al,0
    jmp LoginExit
LoginStart:
    call ClearScreen
    mov dx,OFFSET loginHeader
    call PrintDollarString
    call PrintNewLine

    mov dx,OFFSET loginUserPrompt
    call PrintDollarString
    mov dx,OFFSET usernameInput
    call ReadLine
    call PrintNewLine
    mov al,[usernameInput+1]
    cmp al,0
    je LoginFail

    mov dx,OFFSET loginPassPrompt
    call PrintDollarString
    mov dx,OFFSET passwordInput
    call ReadLine
    call PrintNewLine
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
    call ClearScreen
    mov dx,OFFSET authMenuHeader
    call PrintDollarString
    mov ah,01h
    int 21h
    cmp al,'1'
    je AuthDoLogin
    cmp al,'2'
    je AuthDoRegister
    cmp al,'3'
    je AuthExit
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
    call ClearScreen
    mov dx,OFFSET createHeader
    call PrintDollarString
    call PrintNewLine
    mov dx,OFFSET slotIdPrompt
    call PrintDollarString
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    call PrintNewLine
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

    mov si,ax                ; preserve slot id in SI

    mov dx,OFFSET statusPrompt
    call PrintDollarString
    mov dx,OFFSET statusBuffer
    call ReadLine
    call PrintNewLine
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
    mov byte ptr [plateBuffer+1],0
    jmp CSSave
CSSetOcc:
    mov dx,OFFSET platePrompt
    call PrintDollarString
    mov dx,OFFSET plateBuffer
    call ReadLine
    call PrintNewLine
    mov al,[plateBuffer+1]
    cmp al,0
    jne CSPlateOk
    jmp CSInvalid
CSPlateOk:
    mov ah,STATUS_OCCUPIED

CSSave:
    mov bl,slotCount
    mov bh,0                 ; BX = index

    ; save slot id
    mov di,OFFSET slotIds
    mov dx,bx
    shl dx,1
    add di,dx
    mov [di],si

    ; save status (AH holds status)
    mov di,OFFSET slotStatus
    add di,bx
    mov [di],ah

    ; save plate length
    mov di,OFFSET slotPlateLens
    add di,bx
    cmp ah,STATUS_OCCUPIED
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
    mov dx,OFFSET slotCreateOk
    call ShowMsgAndPause
    jmp CSDone

CSDuplicate:
    mov dx,OFFSET slotExistsMsg
    call ShowMsgAndPause
    jmp CSStart
CSInvalid:
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp CSStart
CSFull:
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
    call ClearScreen
    mov dx,OFFSET viewHeader
    call PrintDollarString
    call PrintNewLine
    mov dx,OFFSET tableHeader
    call PrintDollarString

    mov byte ptr viewHasRecord,0 ; tracks if any record printed
    mov cl,slotCount
    mov ch,0
    mov si,0                  ; SI used as index
    cmp cx,0
    jne VSLoopCheck
    mov dx,OFFSET noSlotsMsg
    call ShowMsgAndPause
    jmp VSDone
VSLoopCheck:
    cmp si,cx
    jb VSLoop
    jmp VSAfterLoop
VSLoop:
    mov bx,si
    mov di,OFFSET slotStatus
    add di,bx
    mov al,[di]
    cmp al,STATUS_DELETED
    je VSSkip

    mov byte ptr viewHasRecord,1
    ; slot id
    mov ax,si
    shl ax,1
    mov di,OFFSET slotIds
    add di,ax
    mov ax,[di]
    call PrintNumber

    mov dx,OFFSET pipeSep
    call PrintDollarString

    ; status text
    mov di,OFFSET slotStatus
    add di,bx
    mov al,[di]
    call PrintStatusText

    mov dx,OFFSET pipeSep
    call PrintDollarString

    ; plate
    mov di,OFFSET slotPlateLens
    add di,bx
    mov al,[slotStatus+bx]
    cmp al,STATUS_OCCUPIED
    jne VSDash
    mov al,[di]
    cmp al,0
    je VSDash
    mov di,OFFSET slotPlates
    mov ax,si
    push bx
    mov bx,MAX_PLATE_LEN
    mul bx
    pop bx
    add di,ax
    push cx                  ; preserve slotCount in CX
    mov cl,[slotPlateLens+bx]
    mov ch,0
    push si                  ; preserve loop index
    mov si,di
    push bx
    push di
VSPlatePrint:
    cmp cx,0
    je VSAfterPlate
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    loop VSPlatePrint
VSAfterPlate:
    pop di
    pop bx
    pop si
    pop cx
    jmp VSFinishLine
VSDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
VSFinishLine:
    call PrintNewLine
VSSkip:
    inc si
    cmp si,cx
    jae VSAfterLoop
    jmp VSLoop
VSAfterLoop:
    cmp byte ptr viewHasRecord,0
    jne VSHasRecords
    mov dx,OFFSET noSlotsMsg
    call ShowMsgAndPause
    jmp VSDone
VSHasRecords:
    mov dx,OFFSET continueMsg
    call ShowMsgAndPause
VSDone:
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
USStart:
    call ClearScreen
    mov dx,OFFSET updateHeader
    call PrintDollarString
    call PrintNewLine

    mov dx,OFFSET slotIdPrompt
    call PrintDollarString
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    call PrintNewLine
    mov dx,OFFSET slotIdBuffer
    call ParseNumber
    jnc USIdOk
    jmp USInvalid
USIdOk:

    ; locate record
    call FindSlotById
    jnc USFound
    jmp USNotFound
USFound:
    mov bh,0                 ; ensure BX is word index
    mov di,OFFSET slotStatus
    add di,bx
    mov al,[di]
    cmp al,STATUS_DELETED
    jne USRecOk
    jmp USNotFound
USRecOk:

    ; display current values
    mov dx,OFFSET slotIdLabel
    call PrintDollarString
    mov ax,bx
    shl ax,1
    mov di,OFFSET slotIds
    add di,ax
    mov ax,[di]
    call PrintNumber
    call PrintNewLine

    mov dx,OFFSET statusLabel
    call PrintDollarString
    mov al,[slotStatus+bx]
    call PrintStatusText
    call PrintNewLine

    mov dx,OFFSET plateLabel
    call PrintDollarString
    mov al,[slotStatus+bx]
    cmp al,STATUS_OCCUPIED
    jne USShowDash
    mov dl,[slotPlateLens+bx]
    cmp dl,0
    je USShowDash
    mov ax,bx
    mov si,MAX_PLATE_LEN
    mul si
    mov di,OFFSET slotPlates
    add di,ax
    mov cl,[slotPlateLens+bx]
    mov ch,0
    mov si,di
USPlatePrint:
    cmp cx,0
    je USPlateDone
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    loop USPlatePrint
USPlateDone:
    jmp USAfterPlateShow
USShowDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
USAfterPlateShow:
    call PrintNewLine
    call PrintNewLine
    
    mov dl,[slotStatus+bx]
    cmp dl,STATUS_OCCUPIED
    je USOptsOcc
    mov dx,OFFSET updateOptionsFree
    jmp USOptsPrint
USOptsOcc:
    mov dx,OFFSET updateOptions
USOptsPrint:
    call PrintDollarString
    mov ah,01h
    int 21h
    call PrintNewLine
    cmp al,'1'
    je USChangeStatus
    cmp al,'2'
    je USChoice2
    cmp al,'3'
    jne USBadMenu
    jmp USDone
USChoice2:
    mov dl,[slotStatus+bx]
    cmp dl,STATUS_OCCUPIED
    je USChoice2Plate
    jmp USDone
USChoice2Plate:
    jmp USChangePlate
USBadMenu:
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp USStart

USChangeStatus:
    mov dx,OFFSET statusPrompt
    call PrintDollarString
    mov dx,OFFSET statusBuffer
    call ReadLine
    call PrintNewLine
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
    mov di,OFFSET slotStatus
    add di,bx
    mov [di],al
    cmp al,STATUS_OCCUPIED
    jne USClearPlate
    mov dx,OFFSET platePrompt
    call PrintDollarString
    mov dx,OFFSET plateBuffer
    call ReadLine
    call PrintNewLine
    mov al,[plateBuffer+1]
    cmp al,0
    je USInvalid
    jmp USCopyPlate
USClearPlate:
    mov di,OFFSET slotPlateLens
    add di,bx
    mov byte ptr [di],0
    mov ax,bx
    mov si,MAX_PLATE_LEN
    mul si
    mov di,OFFSET slotPlates
    add di,ax
    mov byte ptr [di],0
    jmp USUpdateDone

USChangePlate:
    mov dx,OFFSET platePrompt
    call PrintDollarString
    mov dx,OFFSET plateBuffer
    call ReadLine
    call PrintNewLine
    mov al,[plateBuffer+1]
    cmp al,0
    je USInvalid
USCopyPlate:
    mov di,OFFSET slotPlateLens
    add di,bx
    mov al,[plateBuffer+1]
    mov [di],al
    mov ax,bx
    mov si,MAX_PLATE_LEN
    mul si
    mov di,OFFSET slotPlates
    add di,ax
    mov dx,OFFSET plateBuffer
    call CopyBufferToDest
USUpdateDone:
    mov dx,OFFSET updateOkMsg
    call ShowMsgAndPause
    jmp USDone

USInvalid:
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp USStart
USNotFound:
    mov dx,OFFSET notFoundMsg
    call ShowMsgAndPause
USDone:
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
DSStart:
    call ClearScreen
    mov dx,OFFSET deleteHeader
    call PrintDollarString
    call PrintNewLine

    mov dx,OFFSET slotIdPrompt
    call PrintDollarString
    mov dx,OFFSET slotIdBuffer
    call ReadLine
    call PrintNewLine
    mov dx,OFFSET slotIdBuffer
    call ParseNumber
    jnc DSIdOk
    jmp DSInvalid
DSIdOk:

    call FindSlotById
    jnc DSFound
    jmp DSNotFound
DSFound:
    mov bh,0                 ; BX = index
    mov al,[slotStatus+bx]
    cmp al,STATUS_DELETED
    jne DSFoundOk
    jmp DSNotFound
DSFoundOk:

    ; show record details
    mov dx,OFFSET slotIdLabel
    call PrintDollarString
    mov ax,bx
    shl ax,1
    mov di,OFFSET slotIds
    add di,ax
    mov ax,[di]
    call PrintNumber
    call PrintNewLine

    mov dx,OFFSET statusLabel
    call PrintDollarString
    mov al,[slotStatus+bx]
    call PrintStatusText
    call PrintNewLine

    mov dx,OFFSET plateLabel
    call PrintDollarString
    mov dl,[slotPlateLens+bx]
    cmp dl,0
    je DSDash
    mov ax,bx
    mov si,MAX_PLATE_LEN
    mul si
    mov di,OFFSET slotPlates
    add di,ax
    mov cl,[slotPlateLens+bx]
    mov ch,0
    mov si,di
DSPlateLoop:
    cmp cx,0
    je DSAfterPlate
    mov dl,[si]
    mov ah,02h
    int 21h
    inc si
    loop DSPlateLoop
DSAfterPlate:
    jmp DSAfterPlateShow
DSDash:
    mov dx,OFFSET dashMsg
    call PrintZeroString
DSAfterPlateShow:
    call PrintNewLine
    call PrintNewLine

    mov dx,OFFSET deleteConfirm
    call PrintDollarString
    mov ah,01h
    int 21h
    call PrintNewLine
    mov ah,al
    call ToUpper
    cmp al,'Y'
    je DSDoDelete
    mov dx,OFFSET continueMsg
    call ShowMsgAndPause
    jmp DSDone

DSDoDelete:
    mov di,OFFSET slotStatus
    add di,bx
    mov byte ptr [di],STATUS_DELETED
    mov dx,OFFSET deleteOkMsg
    call ShowMsgAndPause
    jmp DSDone

DSInvalid:
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
    jmp DSStart
DSNotFound:
    mov dx,OFFSET notFoundMsg
    call ShowMsgAndPause
DSDone:
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
    call ClearScreen
    mov dx,OFFSET mainMenuHeader
    call PrintDollarString
    mov ah,01h
    int 21h
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
    mov dx,OFFSET invalidInputMsg
    call ShowMsgAndPause
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
    call PrintNewLine
    mov dx,OFFSET logoutMsg
    call PrintDollarString
    call WaitForKey
    mov al,0
    ret
MMExit:
    call ExitProgram
MainMenu ENDP

ExitProgram PROC
    call ClearScreen
    mov dx,OFFSET exitMsg
    call PrintDollarString
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
