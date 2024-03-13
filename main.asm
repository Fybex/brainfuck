.model tiny
.data
    tape            dw 10000 dup(?)
    code            db 10000 dup(?)
    codeLastPointer dw ?

.code
                      org  100h

main proc
    ; Clean tape
                      mov  di, offset tape
    clearTape:        
                      mov  word ptr [di], 0
                      add  di, 2
                      cmp  di, 20000
                      jne  clearTape

    ; Read argument
                      mov  si, 80h                  ; Pointer to command line length
                      mov  cl, [si]                 ; Load length of command line
                      add  si, 2                    ; Move to start of command line text
                      mov  dx, si                   ; Store the pointer to the start of the command line text
                      add  si, cx                   ; Move to the end
                      dec  si
                      mov  byte ptr [si], 0         ; Null-terminate the command line argument
                      

    ; Open file using command line argument directly
                      mov  ah, 3Dh
                      mov  al, 0                    ; Open file for reading
    ; DX = Pointer to the file name
                      int  21h
                      mov  bx, ax                   ; Save file handle

    ; Read file content into the code variable
                      mov  ah, 3Fh
                      lea  dx, code
                      mov  cx, 10000                ; Number of bytes to read
                      int  21h

                      add  ax, offset code          ; Add offset to the file content (AX = offset + length)
                      mov  codeLastPointer, ax      ; Save the last pointer

    ; Close file
                      mov  ah, 3Eh
                      int  21h

    ; Intepreter
                      mov  di, offset tape          ; Tape pointer
                      mov  si, offset code

    interpretLoop:    
                      cmp  si, codeLastPointer      ; Check if end of code
                      jne  interpretContinue
                      jmp  finish
    interpretContinue:
                      mov  al, [si]                 ; Load the current command

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

                      inc  si                       ; Skip unknown commands
                      jmp  interpretLoop

    ; Commands
    increment:        
                      inc  word ptr [di]
                      jmp  nextCommand

    decrement:        
                      dec  word ptr [di]
                      jmp  nextCommand

    moveRight:        
                      add  di, 2
                      jmp  nextCommand

    moveLeft:         
                      sub  di, 2
                      jmp  nextCommand

    startLoop:        
                      push si                       ; Save loop start pointer
                      cmp  word ptr [di], 0
                      jz   findLoopEnd              ; Skip loop if 0
                      jmp  nextCommand

    endLoop:          
                      cmp  word ptr [di], 0
                      jnz  repeatLoop               ; Jump back to start if not 0
                      add  sp, 2                    ; Clean up the stack
                      jmp  nextCommand

    findLoopEnd:      
                      mov  cx, 1                    ; Increase loop nest level
    searchLoopEnd:    
                      inc  si                       ; Next command
                      cmp  byte ptr [si], '['
                      je   increaseLoopNest
                      cmp  byte ptr [si], ']'
                      je   decreaseLoopNest
                      jmp  searchLoopEnd
    increaseLoopNest: 
                      inc  cx
                      jmp  searchLoopEnd
    decreaseLoopNest: 
                      dec  cx
                      jnz  searchLoopEnd
                      add  sp, 2                    ; Clean up the stack
                      jmp  nextCommand

    repeatLoop:       
                      pop  si                       ; Get loop start address
                      push si                       ; Save it again
                      jmp  nextCommand

    output:           
                      mov  dx, [di]
                      mov  ah, 02h                  ; Stdout function code
                      cmp  word ptr [di], 0Ah       ; Check if it's a newline
                      jne  outputContinue
                      mov  dl, 0Dh                  ; Add carriage return before newline
                      int  21h
    outputContinue:   
                      mov  dx, [di]
                      int  21h
                      jmp  nextCommand

    inputChar:        
                      mov  ah, 3Fh                  ; Stdin function code
                      mov  bx, 0
                      lea  dx, [di]                 ; Offset into the tape
                      push cx                       ; Save loop counter
                      mov  cx, 1                    ; Number of bytes to read
                      int  21h
                      pop  cx                       ; Restore loop counter
                      or   ax, ax
                      jnz  skipEOF
                      mov  word ptr [di], 0FFFFh    ; Set to -1 if EOF
    skipEOF:          
                      cmp  word ptr [di], 0Dh       ; Read again if it's a carriage return
                      je   inputChar
                    
    nextCommand:      
                      inc  si
                      jmp  interpretLoop

    ; End
    finish:           
                      mov  ah, 4ch
                      int  21h

main endp
end main
