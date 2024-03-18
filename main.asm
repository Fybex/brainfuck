.model tiny
.data
    tape dw 10000 dup(?)
    code db 10000 dup(?)

.code
                      org   100h

main proc
    ; Clean tape and code
                      mov   di, offset tape          ; Tape pointer
                      mov   cx, 20000                ; Number of cells
                      rep   stosw

    ; Read argument
                      mov   si, 82h                  ; Pointer to command line first character
                      mov   cl, [si-2]               ; Load length of command line
                      mov   dx, si                   ; Store the pointer to the start of the command line text
                      add   si, cx                   ; Move to the end
                      mov   byte ptr [si-1], 0       ; Null-terminate the command line argument
                      

    ; Open file using command line argument directly
                      mov   ah, 3Dh                  ; Open file for reading
    ; DX = Pointer to the file name
                      int   21h
                      mov   bx, ax                   ; Save file handle

    ; Read file content into the code variable
                      mov   ah, 3Fh
                      lea   dx, code
                      mov   cx, 10000                ; Number of bytes to read
                      int   21h

    ; Close file
                      mov   ah, 3Eh
                      int   21h

    ; Intepreter
                      mov   di, offset tape          ; Tape pointer
                      mov   si, offset code          ; Start at -1

    interpretLoop:    
                      lodsb                          ; Load the current command
                      cmp   al, 0                    ; Zero if code ends
                      jne   interpretContinue
    ; End of program
                      mov   ah, 4ch
                      int   21h
    interpretContinue:

    ; Command switch
                      cmp   al, '+'
                      je    increment
                      cmp   al, '-'
                      je    decrement
                      cmp   al, '>'
                      je    moveRight
                      cmp   al, '<'
                      je    moveLeft
                      cmp   al, '['
                      je    startLoop
                      cmp   al, ']'
                      je    endLoop
                      cmp   al, '.'
                      je    output
                      cmp   al, ','
                      je    inputChar

                      jmp   interpretLoop

    ; Commands
    increment:        
                      inc   word ptr [di]
                      jmp   interpretLoop

    decrement:        
                      dec   word ptr [di]
                      jmp   interpretLoop

    moveRight:        
                      add   di, 2
                      jmp   interpretLoop

    moveLeft:         
                      sub   di, 2
                      jmp   interpretLoop

    startLoop:        
                      cmp   word ptr [di], 0
                      jz    findLoopEnd              ; Skip loop if 0
                      push  si                       ; Save loop start pointer
                      jmp   interpretLoop

    endLoop:          
                      cmp   word ptr [di], 0
                      jnz   repeatLoop               ; Jump back to start if not 0
                      pop   dx                       ; Clean up the stack in non-used dx register
                      jmp   interpretLoop

    findLoopEnd:      
                      mov   cx, 1                    ; Increase loop nest level
    searchLoopEnd:    
                      lodsb                          ; Next command
                      cmp   al, '['
                      je    increaseLoopNest
                      cmp   al, ']'
                      jne   searchLoopEnd
    ; decreaseLoopNest
                      loop  searchLoopEnd            ; Loop until cx = 0
                      jmp   interpretLoop
    increaseLoopNest: 
                      inc   cx
                      jmp   searchLoopEnd
    repeatLoop:       
                      pop   si                       ; Get loop start address
                      push  si                       ; Save it again
                      jmp   interpretLoop

    output:           
                      mov   dx, [di]
                      mov   ah, 02h                  ; Stdout function code
                      cmp   word ptr [di], 0Ah       ; Check if it's a newline
                      jne   outputContinue
                      mov   dl, 0Dh                  ; Add carriage return before newline
                      int   21h
    outputContinue:   
                      mov   dx, [di]
                      int   21h
                      jmp   interpretLoop

    inputChar:        
                      mov   ah, 3Fh                  ; Stdin function code
                      xor   bx, bx                   ; Stdin file handle (bx = 0)
                      mov   word ptr [di], bx        ; Clear the current cell to hold input correctly
                      lea   dx, [di]                 ; Offset into the tape
                      push  cx                       ; Save loop counter
                      mov   cx, 1                    ; Number of bytes to read
                      int   21h
                      pop   cx                       ; Restore loop counter
                      or    ax, ax                   ; If 0 bytes read, it's EOF
                      jnz   skipEOF
                      dec   word ptr [di]            ; Set to -1 if EOF (it was 0 before, so dec can be used)
    skipEOF:          
                      cmp   word ptr [di], 0Dh       ; Read again if it's a carriage return
                      je    inputChar
                      jmp   interpretLoop

main endp
end main
