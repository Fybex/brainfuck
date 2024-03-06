.model tiny
.data
    filename db 128 dup(0)
    code     db 10000 dup(0)
    codeLen  dw 0
    tape     db 10000 dup(0)
    input    db 10000 dup(0)

.code
                org 100h

main proc
    ; Read argument
                xor di, di                       ; Clear filename index
                mov si, offset 82h               ; Set SI to point to the command line
    copyLoop:   
                mov al, [si]                     ; Load character from command line
                cmp al, 0Dh                      ; Compare with carriage return
                je  finishCopy
                mov [filename+di], al
                inc di
                inc si                           ; Move to next character in command line
                jmp copyLoop

    finishCopy: 
                mov byte ptr [filename+di], 0    ; Null-terminate filename

    ; Read input
                xor bx, bx                       ; Clear input index
    readChar:   
                mov ah, 3Fh                      ; Stdin function code
                mov bx, 0                        ; File handle 0 (stdin)
                lea dx, input                    ; Pointer to the input buffer
                mov cx, 10000                    ; Maximum number of bytes to read
                int 21h
                mov di, ax                       ; Save number of bytes read
                mov [input+di], 0                ; Null-terminate input

    ; Write output
                xor bx, bx                       ; Clear input index
    writeChar:  
                cmp [input+bx], 0                ; Check for null-terminator
                je  finishWrite
                mov dl, [input+bx]
                mov ah, 02h                      ; Function code for writing char to stdout
                int 21h
                inc bx
                jmp writeChar
    finishWrite:
                xor bx, bx                       ; Clear input index
    
    ; Get content of code file into code variable
    ; Open file
                mov ah, 3Dh
                mov al, 0                        ; Open file for reading
                lea dx, filename
                int 21h
                mov bx, ax                       ; Save file handle

    ; Read file content into the code variable
                mov ah, 3Fh
                lea dx, code
                mov cx, 10000                    ; Number of bytes to read
                int 21h

    ; Save number of bytes read
                mov codeLen, ax

    ; Close file
                mov ah, 3Eh
                int 21h
                 
    finish:     
                mov ah, 4ch
                int 21h

main endp
end main
