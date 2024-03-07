.model tiny
.data
    tape     db 10000 dup(0)
    filename db 128 dup(0)
    code     db 10000 dup(0)
    codeLen  dw 0

.code
                      org  100h

main proc
    ; Read argument
                      xor  di, di                       ; Clear filename index
                      mov  si, offset 82h               ; Set SI to point to the command line
    copyLoop:         
                      mov  al, [si]                     ; Load character from command line
                      cmp  al, 0Dh                      ; Compare with carriage return
                      je   finishCopy
                      mov  [filename+di], al
                      inc  di
                      inc  si                           ; Move to next character in command line
                      jmp  copyLoop

    finishCopy:       
                      mov  byte ptr [filename+di], 0    ; Null-terminate filename
    
    ; Get content of code file into code variable
    ; Open file
                      mov  ah, 3Dh
                      mov  al, 0                        ; Open file for reading
                      lea  dx, filename
                      int  21h
                      mov  bx, ax                       ; Save file handle

    ; Read file content into the code variable
                      mov  ah, 3Fh
                      lea  dx, code
                      mov  cx, 10000                    ; Number of bytes to read
                      int  21h

    ; Save number of bytes read
                      mov  codeLen, ax

    ; Close file
                      mov  ah, 3Eh
                      int  21h

    ; Intepreter
                      xor  di, di                       ; Tape pointer
                      xor  si, si                       ; Code pointer

    interpretLoop:    
                      cmp  si, codeLen                  ; Check if end of code
                      jne  interpretContinue
                      jmp  finish
    interpretContinue:
                      mov  al, [code + si]              ; Load the current command

    ; Command switch
                      cmp  al, '+'
                      je   increment
                      cmp  al, '-'
                      je   decrement
                      cmp  al, '>'
                      je   moveRight
                      cmp  al, '<'
                      je   moveLeft
                      cmp  al, '['
                      je   startLoop
                      cmp  al, ']'
                      je   endLoop
                      cmp  al, '.'
                      je   output
                      cmp  al, ','
                      je   inputChar

                      inc  si                           ; Skip unknown commands
                      jmp  interpretLoop

    ; Commands
    increment:        
                      inc  byte ptr [tape + di]
                      jmp  nextCommand

    decrement:        
                      dec  byte ptr [tape + di]
                      jmp  nextCommand

    moveRight:        
                      inc  di
                      jmp  nextCommand

    moveLeft:         
                      dec  di
                      jmp  nextCommand

    startLoop:        
                      push si                           ; Save loop start pointer
                      cmp  byte ptr [tape + di], 0
                      jz   findLoopEnd                  ; Skil loop if 0
                      jmp  nextCommand

    endLoop:          
                      cmp  byte ptr [tape + di], 0
                      jnz  repeatLoop                   ; Jump back to start if not 0
                      add  sp, 2                        ; Clean up the stack
                      jmp  nextCommand

    findLoopEnd:      
                      inc  si                           ; Next command
                      mov  cx, 1                        ; Increase loop nest level
    searchLoopEnd:    
                      cmp  byte ptr [code + si], '['
                      je   increaseLoopNest
                      cmp  byte ptr [code + si], ']'
                      je   decreaseLoopNest
                      inc  si
                      cmp  si, codeLen                  ; Avoid overflow
                      jne  searchLoopEnd
                      jmp  nextCommand                  ; Safety jump
    increaseLoopNest: 
                      inc  cx
                      jmp  searchLoopEnd
    decreaseLoopNest: 
                      dec  cx
                      jnz  searchLoopEnd
                      add  sp, 2                        ; Clean up the stack
                      jmp  nextCommand

    repeatLoop:       
                      pop  si                           ; Get loop start address
                      push si                           ; Save it again
                      jmp  nextCommand

    output:           
                      mov  dl, [tape + di]
                      mov  ah, 02h                      ; Stdout function code
                      int  21h
                      jmp  nextCommand

    inputChar:        
                      mov  ah, 01h                      ; Stdin function code
                      int  21h
                      mov  [tape + di], al
                      jmp  nextCommand

    nextCommand:      
                      inc  si
                      jmp  interpretLoop

    ; End
    finish:           
                      mov  ah, 4ch
                      int  21h

main endp
end main
