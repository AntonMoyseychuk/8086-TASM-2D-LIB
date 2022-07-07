.286
.model small
.stack 100h

.data
	line_t struc
		m_x0 dw ?
		m_y0 dw ?
		
		m_xEnd dw ?
		m_yEnd dw ?
		
		m_lColor db ?
	line_t ends
	
	circle_t struc
		m_xCent dw ?
		m_yCent dw ?
		
		m_rad dw ?
		
		m_cColor db ?
	circle_t ends
	
	rect_t struc
		m_x dw ? 	;Upper left corner position
		m_y dw ?
		
		m_length dw ?
		m_height dw ?
		
		m_rColor db ?
	rect_t ends
	
	line line_t <10, 10, 310, 190, 01h>
	rect rect_t <10, 10, 50, 25, 0Bh>
	
.code
	__set_video_mode macro mode
		push ax
		
		mov ax, mode
		mov ah, 00h
		int 10h
		
		pop ax
	endm
	
	__set_pixel macro x, y, colour
		pusha
		
		mov cx, x
		mov dx, y
		mov al, colour
		
		mov bh, 0 				;Video page number
		
		mov ah, 0Ch		
		int 10h
		
		popa
	endm
	
	__push_line__ macro line
		push [line]
		push [line + 2]
		push [line + 2 * 2]
		push [line + 3 * 2]
		push [line + 4 * 2]
	endm
	
	__pop_line__ macro line
		pop [line + 4 * 2]
		pop [line + 3 * 2]
		pop [line + 2 * 2]
		pop [line + 2]
		pop [line]
	endm
	
	__push_rect__ macro rect
		push [rect]
		push [rect + 2]
		push [rect + 2 * 2]
		push [rect + 3 * 2]
		push [rect + 4 * 2]
	endm
	
	__pop_rect__ macro rect
		pop [rect + 4 * 2]
		pop [rect + 3 * 2]
		pop [rect + 2 * 2]
		pop [rect + 2]
		pop [rect]
	endm
	
	
	main proc
		mov ax, @data
		mov ds, ax	
		
		__set_video_mode 0Dh
		
		
		update_loop:
			lea di, rect
			lea si, line
			call print_rect
			inc [di].m_rColor
			
			lea di, line
			call print_line
			inc [di].m_lColor

			mov ah, 01h
			int 21h
			
			cmp al, 1Bh
			jne update_loop
		
		__set_video_mode 03h
		
		mov ah, 4Ch
		int 21h
	endp	
	
	print_line proc ;(di <- line_t)
		pusha
		pushf
		__push_line__ di
		
		mov ax, [di].m_xEnd
		sub ax, [di].m_x0		;ax <- deltaX
		
		mov bx, [di].m_yEnd
		sub bx, [di].m_y0		;bx <- deltaY
		
		
		cmp ax, 0
		je zero_deltaX
		jl abs_deltaX
		mov dx, 1				;dx <- xInc
		
		deltaY_check:
		cmp bx, 0
		je zero_deltaY
		jl abs_deltaY
		mov si, 1				;si <- yInc
		jmp correct_args
		
		zero_deltaX:
			mov dx, 0
			jmp deltaY_check
		
		abs_deltaX:
			neg ax				;ax <- |deltaX|
			mov dx, -1
			jmp deltaY_check
		
		zero_deltaY:
			mov si, 0
			jmp correct_args
			
		abs_deltaY:
			neg bx				;bx <- |deltaY|
			mov si, -1
		
		correct_args:
			cmp ax, bx
			jge DX_greater_DY
			jmp DX_less_DY
			
			DX_greater_DY:
				mov cx, bx
				add cx, bx
				sub cx, ax		;cx = coeff = 2 * deltaY - deltaX
			
				l1:
					__set_pixel [di].m_x0, [di].m_y0, [di].m_lColor
					
					add [di].m_x0, dx		;x += xInc
			
					cmp cx, 0
					jl coeff_less_zero_l1
					jmp coeff_greater_or_equal_zero_l1
					
					coeff_less_zero_l1:
						add cx, bx
						add cx, bx			;coeff += 2 * deltaY
						jmp check_updatep_condition_l1
						
					coeff_greater_or_equal_zero_l1:
						add [di].m_y0, si	;y += yInc
						
						add cx, bx
						add cx, bx
						sub cx, ax
						sub cx, ax			;coeff += 2 * (deltaY - deltaX)
						jmp check_updatep_condition_l1
					
				check_updatep_condition_l1:
					push ax
					mov ax, [di].m_x0
					cmp ax, [di].m_xEnd
					pop ax
					jne l1
					jmp print_line_end
			
			DX_less_DY:
				mov cx, ax
				add cx, ax
				sub cx, bx					;coeff = 2 * deltaX - deltaY
				
				l2:
					__set_pixel [di].m_x0, [di].m_y0, [di].m_lColor
					
					add [di].m_y0, si		;y += yInc
			
					cmp cx, 0
					jl coeff_less_zero_l2
					jmp coeff_greater_or_equal_zero_l2
					
					coeff_less_zero_l2:
						add cx, ax
						add cx, ax			;coeff += 2 * deltaX
						jmp check_updatep_condition_l2
						
					coeff_greater_or_equal_zero_l2:
						add [di].m_x0, dx	;x += xInc
						
						add cx, ax
						add cx, ax
						sub cx, bx
						sub cx, bx			;coeff += 2 * (deltaY - deltaX)
						jmp check_updatep_condition_l2
					
				check_updatep_condition_l2:
					push ax
					mov ax, [di].m_y0
					cmp ax, [di].m_yEnd
					pop ax
					jne l2
			
		
		print_line_end:	
		
		__pop_line__ di
		popf
		popa
		ret
	print_line endp
	
	
	print_rect proc ;(di <- rect_t, si <- line_t)
		pusha
		pushf
		__push_rect__ di
		__push_line__ si
		
		mov al, [di].m_rColor
		mov [si].m_lColor, al			;line_t.color = rect_t.color
		
		mov ax, [di].m_y			
		mov [si].m_y0, ax				;line_t.m_y0 = rect_t.m_y
		
		add ax, [di].m_height		
		mov [si].m_yEnd, ax				;line_t.m_yEnd = rect_t.m_y + rect_t.m_height
		
		mov ax, [di].m_x
		mov [si].m_x0, ax				;line_t.m_x0 = rect_t.m_x
		mov [si].m_xEnd, ax				;line_t.m_xEnd = line_t.m_x0 = rect_t.m_x
		
		xchg si, di
		mov cx, [si].m_length
		rect_printing_loop:
			call print_line
			
			inc [di].m_x0 
			inc [di].m_xEnd
			
			loop rect_printing_loop
			
		xchg si, di
		
		__pop_line__ si
		__pop_rect__ di
		popf
		popa
		ret
	print_rect endp
	
end main