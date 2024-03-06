.model tiny
.data
    filename db 128 dup(0)
    code     db 10000 dup(0)
    codeLen  dw 0
    tape     db 10000 dup(0)
    input    db 10000 dup(0)

.code
                               org  100h

readArgument proc
                               mov  si, offset 82h                ; Set SI to point to the command line
    copyLoop:                  
                               mov  al, [si]                      ; Load character from command line
                               cmp  al, 0Dh                       ; Compare with carriage return
                               je   finishCopy
                               mov  [filename+di], al
                               inc  di
                               inc  si                            ; Move to next character in command line
                               jmp  copyLoop

    finishCopy:                
                               mov  byte ptr [filename+di], 0     ; Null-terminate filename
                               ret
readArgument endp

getFileContentIntoVariable proc
    ; Open file
                               mov  ah, 3Dh
                               mov  al, 0                         ; Open file for reading
                               lea  dx, filename
                               int  21h
                               mov  bx, ax                        ; Save file handle

    ; Read file content into the code variable
                               mov  ah, 3Fh
                               lea  dx, code
                               mov  cx, 10000                     ; Number of bytes to read
                               int  21h

    ; Save number of bytes read
                               mov  codeLen, ax

    ; Close file
                               mov  ah, 3Eh
                               xor  bx, bx
                               int  21h
                               ret
getFileContentIntoVariable endp

readInput proc
                               xor  bx, bx                        ; Clear input index
    readChar:                  
                               mov  ah, 01h                       ; Function code for reading char from stdin
                               int  21h
                               cmp  al, 0Dh                       ; Compare with carriage return
                               je   finishRead                    ; If Enter, finish reading
                               mov  [input+bx], al
                               inc  bx
                               jmp  readChar
    finishRead:                
                               mov  [input+bx], 0                 ; Null-terminate the string
                               ret
readInput endp

writeOutput proc
                               xor  bx, bx                        ; Clear input index
    writeChar:                 
                               cmp  [input+bx], 0                 ; Check for null-terminator
                               je   finishOutput
                               mov  dl, [input+bx]
                               mov  ah, 02h                       ; Function code for writing char to stdout
                               int  21h
                               inc  bx
                               jmp  writeChar
    finishOutput:              
                               ret
writeOutput endp
                               

main proc
                               call readArgument
                               call readInput
                               call getFileContentIntoVariable
                               call writeOutput

                               mov  ah, 4ch
                               int  21h

main endp
end main
