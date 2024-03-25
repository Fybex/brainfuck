.model tiny
.data
    tape dw 10000 dup(?)
    code db 10000 dup(?)

.code
                      org   100h

main proc
    ; Clean tape and code
                      mov   di, offset tape       ; Tape pointer
                      push  di                    ; Save tape pointer
                      mov   cx, 20000             ; Number of cells
                      push  cx                    ; Save 20000
                      rep   stosw

    ; Read argument
                      mov   bl, ds:[80h]          ; Pointer to the command line length
                      mov   [81h+bx], al          ; Null-terminate the command line argument (al = 0)
                      

    ; Open file using command line argument directly
                      mov   ah, 3Dh               ; Open file for reading
    ; DX = Pointer to the file name
                      mov   dx, 82h               ; Pointer to the command line argument
                      int   21h
                      xchg  bx, ax                ; Save file handle

    ; Read file content into the code variable
                      mov   ah, 3Fh
                      pop   cx                    ; Number of bytes to read (need only 10000, but 20000 is ok as well)
                      mov   dx, offset code
                      push  dx                    ; Save the pointer to the code variable
                      int   21h

    ; Close file
                      mov   ah, 3Eh
                      int   21h

    ; Intepreter
                      xor   bx, bx                ; Stdin file handle (bx = 0)
                        
                      pop   si                    ; Restore code pointer
                      pop   di                    ; Restore tape pointer
                      

    interpretLoop:    
                      lodsb                       ; Load the current command
                      test  al, al                ; Zero if code ends
                      jnz   increment
    ; End of program
                      ret

    ; Commands
    increment:        
                      cmp   al, '+'
                      jne   decrement
                      inc   word ptr [di]

    decrement:        
                      cmp   al, '-'
                      jne   moveRight
                      dec   word ptr [di]

    moveRight:        
                      cmp   al, '>'
                      jne   moveLeft
    ; Move to the next cell
                      inc   di
                      inc   di

    moveLeft:         
                      cmp   al, '<'
                      jne   startLoop
    ; Move to the previous cell
                      dec   di
                      dec   di

    startLoop:        
                      cmp   al, '['
                      jne   endLoop
                      cmp   word ptr [di], bx
                      jz    findLoopEnd           ; Skip loop if 0
                      push  si                    ; Save loop start pointer

    endLoop:          
                      cmp   al, ']'
                      jne   output
                      cmp   word ptr [di], bx
                      jnz   repeatLoop            ; Jump back to start if not 0
                      pop   dx                    ; Clean up the stack in non-used dx register
                      jmp   interpretLoop
    repeatLoop:       
                      pop   si                    ; Get loop start address
                      push  si                    ; Save it again

    output:           
                      cmp   al, '.'
                      jne   inputChar
                      mov   ah, 02h               ; Stdout function code
                      cmp   word ptr [di], 0Ah    ; Check if it's a newline
                      jne   outputContinue
                      mov   dl, 0Dh               ; Add carriage return before newline
                      int   21h
    outputContinue:   
                      mov   dx, [di]
                      int   21h

    inputChar:        
                      cmp   al, ','
                      jne   interpretLoop
    inputCharContinue:
                      mov   ah, 3Fh               ; Stdin function code
                      mov   word ptr [di], bx     ; Clear the current cell to hold input correctly
                      lea   dx, [di]              ; Offset into the tape
                      mov   cx, 1                 ; Number of bytes to read
                      int   21h
                      test  ax, ax                ; If 0 bytes read, it's EOF
                      jnz   skipEOF
                      dec   word ptr [di]         ; Set to -1 if EOF (it was 0 before, so dec can be used)
    skipEOF:          
                      cmp   word ptr [di], 0Dh    ; Read again if it's a carriage return
                      je    inputCharContinue
                      jmp   interpretLoop

    findLoopEnd:      
                      mov   cx, 1                 ; Increase loop nest level
    searchLoopEnd:    
                      lodsb                       ; Next command
                      cmp   al, '['
                      je    increaseLoopNest
                      cmp   al, ']'
                      jne   searchLoopEnd
    ; decreaseLoopNest
                      loop  searchLoopEnd         ; Loop until cx = 0
                      jmp   interpretLoop
    increaseLoopNest: 
                      inc   cx
                      jmp   searchLoopEnd

main endp
end main
