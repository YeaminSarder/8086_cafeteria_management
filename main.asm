.MODEL SMALL
.STACK 100H

.DATA
PASSWORD        DB '1234'
PASSWORD_LEN    DB 4

PW_PROMPT       DB 'Enter admin password: $'
PW_FAIL         DB 13,10,'Invalid password. Try again.',13,10,'$'

MENU_TEXT       DB 13,10,'1. Stock Dashboard',13,10
                DB '2. Add Inventory',13,10
                DB '3. Update Price',13,10
                DB '4. Low Stock Audit',13,10
                DB '5. Total Asset Valuation',13,10
                DB '6. Exit',13,10
                DB 'Select option: $'
INVALID_CHOICE  DB 13,10,'Invalid selection.',13,10,'$'

DASH_HEADER     DB 13,10,'Current Stock:',13,10,'$'
DASH_ID_SEP     DB '. $'
DASH_SEP        DB ' : $'
DASH_PRICE_SEP  DB '  Price: $'

ADD_PROMPT_ID   DB 13,10,'Enter item ID (1-5): $'
ADD_PROMPT_QTY  DB 13,10,'Enter quantity to add: $'
ADD_DONE        DB 13,10,'Stock updated.',13,10,'$'

PRICE_PROMPT_ID DB 13,10,'Enter item ID (1-5): $'
PRICE_PROMPT_NEW DB 13,10,'Enter new price: $'
PRICE_DONE      DB 13,10,'Price updated.',13,10,'$'

AUDIT_HEADER    DB 13,10,'Low Stock Audit:',13,10,'$'
WARN_TEXT       DB ' - LOW STOCK$'
MIN_STOCK       DW 5

TOTAL_HEADER    DB 13,10,'Total inventory value: $'

CRLF            DB 13,10,'$'

Item1           DB 'Coffee$'
Item2           DB 'Tea$'
Item3           DB 'Sandwich$'
Item4           DB 'Muffin$'
Item5           DB 'Juice$'

ProductPtrs     DW OFFSET Item1, OFFSET Item2, OFFSET Item3, OFFSET Item4, OFFSET Item5

StockArray      DW 10, 8, 4, 6, 3
PriceArray      DW 5, 4, 7, 3, 6

GRAND_TOTAL     DW 0

PW_BUF          DB 8,0,8 DUP (?)
NUM_BUF         DB 5,0,5 DUP (?)

.CODE
MAIN PROC
    MOV AX,@DATA
    MOV DS,AX
    MOV ES,AX
    CLD

AUTH_LOOP:
    LEA DX, PW_PROMPT
    MOV AH,09H
    INT 21H

    LEA DX, PW_BUF
    MOV AH,0AH
    INT 21H

    LEA DX, CRLF
    MOV AH,09H
    INT 21H

    MOV AL, [PW_BUF+1]
    CMP AL, [PASSWORD_LEN]
    JNE AUTH_FAIL

    PUSH DS
    POP ES
    LEA SI, PASSWORD
    LEA DI, PW_BUF+2
    MOV CL, [PASSWORD_LEN]
    XOR CH, CH
    REPE CMPSB
    JE AUTH_OK

AUTH_FAIL:
    LEA DX, PW_FAIL
    MOV AH,09H
    INT 21H
    JMP AUTH_LOOP

AUTH_OK:
MENU_LOOP:
    LEA DX, MENU_TEXT
    MOV AH,09H
    INT 21H

    CALL ReadNumber
    CMP AX,1
    JE MENU_DASH
    CMP AX,2
    JE MENU_ADD
    CMP AX,3
    JE MENU_PRICE
    CMP AX,4
    JE MENU_AUDIT
    CMP AX,5
    JE MENU_TOTAL
    CMP AX,6
    JE EXIT_PROGRAM

    LEA DX, INVALID_CHOICE
    MOV AH,09H
    INT 21H
    JMP MENU_LOOP

MENU_DASH:
    CALL PrintDashboard
    JMP MENU_LOOP

MENU_ADD:
    CALL AddInventory
    JMP MENU_LOOP

MENU_PRICE:
    CALL UpdatePrice
    JMP MENU_LOOP

MENU_AUDIT:
    CALL LowStockAudit
    JMP MENU_LOOP

MENU_TOTAL:
    CALL TotalValuation
    JMP MENU_LOOP

EXIT_PROGRAM:
    MOV AX,4C00H
    INT 21H
MAIN ENDP

PrintDashboard PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    LEA DX, DASH_HEADER
    MOV AH,09H
    INT 21H

    MOV CX,5
    XOR SI,SI
    XOR DI,DI

PD_LOOP:
    MOV AX, DI
    INC AX
    CALL PrintNum

    LEA DX, DASH_ID_SEP
    MOV AH,09H
    INT 21H

    MOV BX, ProductPtrs[SI]
    MOV DX, BX
    MOV AH,09H
    INT 21H

    LEA DX, DASH_SEP
    MOV AH,09H
    INT 21H

    MOV AX, StockArray[SI]
    CALL PrintNum

    LEA DX, DASH_PRICE_SEP
    MOV AH,09H
    INT 21H

    MOV AX, PriceArray[SI]
    CALL PrintNum

    LEA DX, CRLF
    MOV AH,09H
    INT 21H

    ADD SI,2
    INC DI
    LOOP PD_LOOP

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintDashboard ENDP

AddInventory PROC
    PUSH AX
    PUSH BX
    PUSH DX

    CALL PrintDashboard

    LEA DX, ADD_PROMPT_ID
    MOV AH,09H
    INT 21H

    CALL ReadNumber
    CMP AX,1
    JL AI_BAD
    CMP AX,5
    JG AI_BAD
    DEC AX
    MOV BL, 2
    MUL BL
    MOV BX, AX

    LEA DX, ADD_PROMPT_QTY
    MOV AH,09H
    INT 21H

    CALL ReadNumber
    MOV DX, AX

    MOV AX, StockArray[BX]
    ADD AX, DX
    MOV StockArray[BX], AX

    LEA DX, ADD_DONE
    MOV AH,09H
    INT 21H
    JMP AI_DONE

AI_BAD:
    LEA DX, INVALID_CHOICE
    MOV AH,09H
    INT 21H

AI_DONE:
    POP DX
    POP BX
    POP AX
    RET
AddInventory ENDP

UpdatePrice PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH SI

    CALL PrintDashboard

    LEA DX, PRICE_PROMPT_ID
    MOV AH,09H
    INT 21H

    CALL ReadNumber
    CMP AX,1
    JL UP_BAD
    CMP AX,5
    JG UP_BAD
    DEC AX
    MOV BL, 2
    MUL BL
    MOV BX, AX

    LEA DX, PRICE_PROMPT_NEW
    MOV AH,09H
    INT 21H

    CALL ReadNumber
    MOV PriceArray[BX], AX

    LEA DX, PRICE_DONE
    MOV AH,09H
    INT 21H
    JMP UP_DONE

UP_BAD:
    LEA DX, INVALID_CHOICE
    MOV AH,09H
    INT 21H

UP_DONE:
    POP SI
    POP DX
    POP BX
    POP AX
    RET
UpdatePrice ENDP

LowStockAudit PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    LEA DX, AUDIT_HEADER
    MOV AH,09H
    INT 21H

    MOV CX,5
    XOR SI,SI

LS_LOOP:
    MOV AX, StockArray[SI]
    CMP AX, [MIN_STOCK]
    JGE LS_SKIP

    MOV BX, ProductPtrs[SI]
    MOV DX, BX
    MOV AH,09H
    INT 21H

    LEA DX, WARN_TEXT
    MOV AH,09H
    INT 21H

    LEA DX, CRLF
    MOV AH,09H
    INT 21H

LS_SKIP:
    ADD SI,2
    LOOP LS_LOOP

    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
LowStockAudit ENDP

TotalValuation PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI

    MOV GRAND_TOTAL,0
    MOV CX,5
    XOR SI,SI
    XOR DI,DI

TV_LOOP:
    MOV AX, PriceArray[SI]
    MOV BX, StockArray[DI]
    MUL BX
    ADD GRAND_TOTAL, AX
    ADD SI, 2
    ADD DI, 2
    LOOP TV_LOOP

    LEA DX, TOTAL_HEADER
    MOV AH,09H
    INT 21H

    MOV AX, GRAND_TOTAL
    CALL PrintNum

    LEA DX, CRLF
    MOV AH,09H
    INT 21H

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TotalValuation ENDP

ReadNumber PROC
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI

    LEA DX, NUM_BUF
    MOV AH,0AH
    INT 21H

    MOV CL, [NUM_BUF+1]
    MOV CH,0
    MOV SI, OFFSET NUM_BUF+2
    XOR AX,AX
    MOV BX,10

RN_LOOP:
    CMP CX,0
    JE RN_DONE
    MOV DL, [SI]
    SUB DL, '0'
    MOV DH,0
    PUSH DX
    MUL BX
    POP DX
    ADD AX, DX
    INC SI
    DEC CX
    JMP RN_LOOP

RN_DONE:
    POP SI
    POP DX
    POP CX
    POP BX
    RET
ReadNumber ENDP

PrintNum PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    MOV CX,0
    MOV BX,10
    CMP AX,0
    JNE PN_LOOP
    MOV DL,'0'
    MOV AH,02H
    INT 21H
    JMP PN_DONE

PN_LOOP:
    XOR DX,DX
    DIV BX
    PUSH DX
    INC CX
    CMP AX,0
    JNE PN_LOOP

PN_PRINT:
    POP DX
    ADD DL,'0'
    MOV AH,02H
    INT 21H
    LOOP PN_PRINT

PN_DONE:
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PrintNum ENDP

END MAIN
