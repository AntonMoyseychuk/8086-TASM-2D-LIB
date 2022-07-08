.286
.model small
.stack 100h

.data
	;###########################################
	;#                STUCTURES                #
	;###########################################
	
	line_t struc
		m_x0 dw ?
		m_y0 dw ?
		
		m_xEnd dw ?
		m_yEnd dw ?
		
		m_lColor db ?
	line_t ends
	
	;_temp_line is used to draw rectangles 
	;Not intended for user use
	_temp_line line_t <>
	
	circle_t struc
		m_xCent dw ?
		m_yCent dw ?
		
		m_rad dw ?
		
		m_cColor db ?
	circle_t ends
	
	rect_t struc
		m_x dw ?	;Upper left corner X position
		m_y dw ?	;Upper left corner Y position
		
		m_length dw ?
		m_height dw ?
		
		m_rColor db ?
	rect_t ends
	
	;###########################################
	;#                VARIABLES                #
	;###########################################
	
	line line_t <10, 10, 110, 110, 01h>
	rect1 rect_t <10, 10, 100, 100, 05h>
	rect2 rect_t <12, 12, 40, 40, 0Ah>
	
.code
	;###########################################
	;#                 MACROS                  #
	;###########################################

	;Utility macro to push a line to the stack
	__push_line__ macro line
		push [line]
		push [line + 2]
		push [line + 2 * 2]
		push [line + 3 * 2]
		push [line + 4 * 2]
	endm
	
	;Utility macro to pop a line from the stack
	__pop_line__ macro line
		pop [line + 4 * 2]
		pop [line + 3 * 2]
		pop [line + 2 * 2]
		pop [line + 2]
		pop [line]
	endm
	
	;Utility macro to push a rectangular to the stack
	__push_rect__ macro rect
		push [rect]
		push [rect + 2]
		push [rect + 2 * 2]
		push [rect + 3 * 2]
		push [rect + 4 * 2]
	endm
	
	;Utility macro to pop a rectangular from the stack
	__pop_rect__ macro rect
		pop [rect + 4 * 2]
		pop [rect + 3 * 2]
		pop [rect + 2 * 2]
		pop [rect + 2]
		pop [rect]
	endm
	
	;Macro to set video mode
	;Takes a video mode number as a parameter
	__set_video_mode macro modeNumber
		push ax
		
		mov ax, modeNumber
		mov ah, 00h
		int 10h
		
		pop ax
	endm
	
	;Macro for drawing a pixel
	;Takes the coordinates of the pixel and its color as a parameter
	__set_pixel macro x, y, color
		pusha
		
		mov cx, x
		mov dx, y
		mov al, color
		
		mov bh, 0		;Video page number
		
		mov ah, 0Ch		
		int 10h
		
		popa
	endm
	
	
	main proc
		mov ax, @data
		mov ds, ax	
		
		__set_video_mode 0Dh	    ;Color mode setting (320X200)
		
		update_loop:
			lea di, rect1	    ;di <- ptr rect1
			mov si, 0	    ;si <- fill mode
			call print_rect
			inc [di].m_rColor   ;Switch color to next
			
			lea di, rect2	    ;di <- ptr rect2
			mov si, 1           ;si <- fill mode
			call print_rect     
			inc [di].m_rColor   ;Switch color to next
			
			lea di, line	    ;di <- ptr line
			call print_line
			inc [di].m_lColor   ;Switch color to next

			mov ah, 01h	    ;Сharacter input function without echo
			int 21h
			
			cmp al, 1Bh	    ;Check for pressing the ESC key
			jne update_loop
		
		__set_video_mode 03h	    ;Text mode setting (80X25)
		
		mov ah, 4Ch		    ;Transfer control to the operating system
		int 21h
	endp

	
	;###########################################
	;#               PROCEDURES                #
	;###########################################
	
	;Takes a pointer to a line_t object 
	;in register di as a parameter
	print_line proc
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
		mov dx, 1			;dx <- xInc
		
		deltaY_check:
		cmp bx, 0
		je zero_deltaY
		jl abs_deltaY
		mov si, 1			;si <- yInc
		jmp correct_args
		
		zero_deltaX:
			mov dx, 0
			jmp deltaY_check
		
		abs_deltaX:
			neg ax			;ax <- |deltaX|
			mov dx, -1
			jmp deltaY_check
		
		zero_deltaY:
			mov si, 0
			jmp correct_args
			
		abs_deltaY:
			neg bx			;bx <- |deltaY|
			mov si, -1
		
		correct_args:
			cmp ax, bx
			jge DX_greater_DY
			jmp DX_less_DY
			
			DX_greater_DY:
				mov cx, bx
				add cx, bx
				sub cx, ax	;cx <- coeff = 2 * deltaY - deltaX
			
				l1:
					__set_pixel [di].m_x0, [di].m_y0, [di].m_lColor
					
					add [di].m_x0, dx	;x += xInc
			
					cmp cx, 0
					jl coeff_less_zero_l1
					jmp coeff_greater_or_equal_zero_l1
					
					coeff_less_zero_l1:
						add cx, bx
						add cx, bx	;coeff += 2 * deltaY
						jmp check_updatep_condition_l1
						
					coeff_greater_or_equal_zero_l1:
						add [di].m_y0, si	;y += yInc
						
						add cx, bx
						add cx, bx
						sub cx, ax
						sub cx, ax	;coeff += 2 * (deltaY - deltaX)
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
				sub cx, bx			;cx <- coeff = 2 * deltaX - deltaY
				
				l2:
					__set_pixel [di].m_x0, [di].m_y0, [di].m_lColor
					
					add [di].m_y0, si	;y += yInc
			
					cmp cx, 0
					jl coeff_less_zero_l2
					jmp coeff_greater_or_equal_zero_l2
					
					coeff_less_zero_l2:
						add cx, ax
						add cx, ax		;coeff += 2 * deltaX
						jmp check_updatep_condition_l2
						
					coeff_greater_or_equal_zero_l2:
						add [di].m_x0, dx	;x += xInc
						
						add cx, ax
						add cx, ax
						sub cx, bx
						sub cx, bx		;coeff += 2 * (deltaY - deltaX)
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
	
	;Takes a pointer to a rect_t object in the di register 
	;and a fill flag in the si register as a parameter
	print_rect proc
		pusha
		pushf
		__push_rect__ di
		
		mov cx, si				;cx <- fill_flag
		
		lea si, _temp_line			;si <- _temp_line ptr
			
		mov al, [di].m_rColor
		mov [si].m_lColor, al			;line_t.color = rect_t.color
			
		mov ax, [di].m_y			
		mov [si].m_y0, ax			;line_t.m_y0 = rect_t.m_y
			
		add ax, [di].m_height		
		mov [si].m_yEnd, ax			;line_t.m_yEnd = rect_t.m_y + rect_t.m_height
			
		mov ax, [di].m_x
		mov [si].m_x0, ax			;line_t.m_x0 = rect_t.m_x
		mov [si].m_xEnd, ax			;line_t.m_xEnd = line_t.m_x0 = rect_t.m_x
		
		cmp cx, 0				;check fill_flag != 0
		jne filled_rect
		
		not_filled_rect:
			xchg si, di
			
			call print_line			;printing left border
			
			mov ax, [si].m_length
			add [di].m_x0, ax
			mov ax, [di].m_yEnd
			mov [di].m_y0, ax
			call print_line			;printing bottom border
			
			mov ax, [si].m_height
			sub [di].m_yEnd, ax
			mov ax, [si].m_length
			add [di].m_xEnd, ax
			call print_line			;printing right border
			
			sub [di].m_x0, ax
			mov ax, [si].m_height
			sub [di].m_y0, ax
			call print_line			;printing top border
			
			xchg si, di
			
			jmp print_rect_end
		
		filled_rect:
			
			xchg si, di
			mov cx, [si].m_length
			rect_printing_loop:
				call print_line
				
				inc [di].m_x0 
				inc [di].m_xEnd
				
				loop rect_printing_loop
				
			xchg si, di
		
		
		print_rect_end:
		__pop_rect__ di
		popf
		popa
		ret
	print_rect endp
	
end main
