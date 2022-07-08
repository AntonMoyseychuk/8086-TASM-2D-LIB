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
		
		m_radius dw ?
		
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
	
	line line_t <110, 150, 210, 50, 0Bh>
	rect1 rect_t <110, 50, 100, 100, 04h>
	rect2 rect_t <112, 52, 40, 40, 01h>
	circle circle_t <185, 125, 24, 0Eh>
	
.code
	;###########################################
	;#                 MACROS                  #
	;###########################################

	;Utility macro to push a line to the stack
	;Arguments: address of line_t source object
	__push_line__ macro ptr_line
		push [ptr_line]
		push [ptr_line + 2]
		push [ptr_line + 2 * 2]
		push [ptr_line + 3 * 2]
		push [ptr_line + 4 * 2]
	endm
	
	
	;Utility macro to pop a line from the stack
	;Arguments: address of line_t destination object
	__pop_line__ macro ptr_line
		pop [ptr_line + 4 * 2]
		pop [ptr_line + 3 * 2]
		pop [ptr_line + 2 * 2]
		pop [ptr_line + 2]
		pop [ptr_line]
	endm
	
	
	;Utility macro to push a rectangular to the stack
	;Arguments: address of rect_t source object
	__push_rect__ macro ptr_rect
		push [ptr_rect]
		push [ptr_rect + 2]
		push [ptr_rect + 2 * 2]
		push [ptr_rect + 3 * 2]
		push [ptr_rect + 4 * 2]
	endm
	
	
	;Utility macro to pop a rectangular from the stack
	;Arguments: address of rect_t destination object
	__pop_rect__ macro ptr_rect
		pop [ptr_rect + 4 * 2]
		pop [ptr_rect + 3 * 2]
		pop [ptr_rect + 2 * 2]
		pop [ptr_rect + 2]
		pop [ptr_rect]
	endm
	
	
	;Utility macro to push a circle to the stack
	;Arguments: address of circle_t source object
	__push_circle__ macro ptr_circle
		push [ptr_circle]
		push [ptr_circle + 2]
		push [ptr_circle + 2 * 2]
		push [ptr_circle + 3 * 2]
	endm
	
	
	;Utility macro to pop a circle from the stack
	;Arguments: address of circle_t destination object
	__pop_circle__ macro ptr_circle
		pop [ptr_circle + 3 * 2]
		pop [ptr_circle + 2 * 2]
		pop [ptr_circle + 2]
		pop [ptr_circle]
	endm
	
	
	;Macro to set video mode
	;Arguments: mode number
	__set_video_mode__ macro modeNumber
		push ax
		
		mov ax, modeNumber
		mov ah, 00h
		int 10h
		
		pop ax
	endm
	
	
	;Macro for drawing a pixel
	;Arguments: coordinates of the pixel and its color
	__set_pixel__ macro x, y, color
		pusha
		
		mov cx, x
		mov dx, y
		mov al, color
		
		mov bh, 0		;Video page number
		
		mov ah, 0Ch		
		int 10h
		
		popa
	endm
	
	;###########################################
	;#              ENTRY POINT                #
	;###########################################
	main proc
		mov ax, @data
		mov ds, ax	
		
		__set_video_mode__ 0Dh	    ;Color mode setting (320X200)
		
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
			
			lea di, circle
			call print_circle
			inc [di].m_cColor

			mov ah, 01h	    ;Сharacter input function without echo
			int 21h
			
			cmp al, 1Bh	    ;Check for pressing the ESC key
			jne update_loop
		
		__set_video_mode__ 03h	    ;Text mode setting (80X25)
		
		mov ah, 4Ch		    ;Transfer control to the operating system
		int 21h
	endp

	
	;###########################################
	;#               PROCEDURES                #
	;###########################################
	
	;Procedure that implements the Brazenham algorithm for a segment
	;Arguments:
	;	di <- address of line_t object
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
			
				printing_line_loop_1:
					__set_pixel__ [di].m_x0, [di].m_y0, [di].m_lColor
					
					add [di].m_x0, dx		;x += xInc
			
					cmp cx, 0
					jl coeff_less_zero_l1
					jmp coeff_greater_or_equal_zero_l1
					
					coeff_less_zero_l1:
						add cx, bx
						add cx, bx		;coeff += 2 * deltaY
						jmp check_update_condition_l1
						
					coeff_greater_or_equal_zero_l1:
						add [di].m_y0, si	;y += yInc
						
						add cx, bx
						add cx, bx
						sub cx, ax
						sub cx, ax		;coeff += 2 * (deltaY - deltaX)
						jmp check_update_condition_l1
					
				check_update_condition_l1:
					push ax
					mov ax, [di].m_x0
					cmp ax, [di].m_xEnd
					pop ax
					jne printing_line_loop_1
					jmp print_line_end
			
			DX_less_DY:
				mov cx, ax
				add cx, ax
				sub cx, bx			;cx <- coeff = 2 * deltaX - deltaY
				
				printing_line_loop_2:
					__set_pixel__ [di].m_x0, [di].m_y0, [di].m_lColor
					
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
					jne printing_line_loop_2
			
		
		print_line_end:	
		
		__pop_line__ di
		popf
		popa
		ret
	print_line endp
	
	
	;Procedure that draws rectangular
	;Arguments:
	;	di <- address of rect_t object
	;	si <- (0 - transparent, not 0 - non-transparent)
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
	
	
	;Procedure that implements Brazenham algorithm for a circle
	;Arguments:
	;	di <- address of circle_t object
	print_circle proc
		pusha
		pushf
		__push_circle__ di
		
		mov ax, 0				;ax = x <- 0
		mov bx, [di].m_radius	;bx = y <- circle_t.radius
		mov cx, 1
		sub cx, bx				;cx = coeff <- (1 - circle_t.radius)
		
		circle_printing_loop:
			pusha
			;Loading arguments into registers
			mov si, [di].m_yCent
			mov dx, ax
			mov cx, bx
			mov bl, [di].m_cColor
			mov di, [di].m_xCent
			call _circle_plot_points_
			popa
			
			inc ax				;x++
			
			cmp cx, 0
			jl coeff_less_zero_circle
			jmp coeff_greater_or_equal_zero_circle
			
			coeff_less_zero_circle:
				add cx, ax
				add cx, ax
				add cx, 3		;coeff += 2*x + 3
				jmp check_update_condition_circle
			
			coeff_greater_or_equal_zero_circle:
				dec bx			;y++
				add cx, ax
				add cx, ax
				sub cx, bx
				sub cx, bx
				add cx, 4		;coeff += 2*x - 2*y + 4
			
			
			check_update_condition_circle:
			;if x <= y then go to start of the circle_printing_loop
			cmp ax, bx
			jle circle_printing_loop
		
		__pop_circle__ di
		popf
		popa
		ret
	print_circle endp
	
	
	;Utility procedure that is used in the 
	;Brazenhem algorithm for a circle.
	;Arguments:
	;	di <- xCenter
	;	si <- yCenter
	;	dx <- x
	;	cx <- y
	;	bx (bl) <- color
	_circle_plot_points_ proc
		pusha
		pushf
		
		push di
		push si
		add di, dx
		add si, cx
		;di <- xCenter + x
		;si <- yCenter + y
		__set_pixel__ di, si, bl
		
		sub si, cx
		sub si, cx
		;di <- xCenter + x
		;si <- yCenter - y
		__set_pixel__ di, si, bl
		
		sub di, dx
		sub di, dx
		;di <- xCenter - x
		;si <- yCenter - y 
		__set_pixel__ di, si, bl
		
		add si, cx
		add si, cx
		;di <- xCenter - x
		;si <- yCenter + y 
		__set_pixel__ di, si, bl
		
		add di, dx
		add di, dx
		;di <- xCenter + x
		;si <- yCenter + y 
		__set_pixel__ di, si, bl
		pop si
		pop di
		
		
		push di
		push si 
		add di, cx
		add si, dx
		;di <- xCenter + y
		;si <- yCenter + x 
		__set_pixel__ di, si, bl
		
		sub si, dx
		sub si, dx
		;di <- xCenter + y
		;si <- yCenter - x 
		__set_pixel__ di, si, bl
		
		sub di, cx
		sub di, cx
		;di <- xCenter - y
		;si <- yCenter - x 
		__set_pixel__ di, si, bl
		
		add si, dx
		add si, dx
		;di <- xCenter - y
		;si <- yCenter - x 
		__set_pixel__ di, si, bl
		pop si
		pop di
		
		popf
		popa
		ret
	_circle_plot_points_ endp
	
end main
