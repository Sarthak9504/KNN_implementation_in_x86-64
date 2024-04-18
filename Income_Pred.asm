section .data
	cols: equ 15
	train_filename db "./train.csv", 0
	train_rows: equ 26048
	test_filename db "./test.csv", 0
	output_filename db "./output2.csv",0
	test_rows: equ 6513
	data_unit_len: equ 3
	buffer_len: equ 60
	
	k db 5

	title db "INCOME PREDICTION USING KNN", 10
	title_len: equ $-title
	
	class1msg db "income > 50k", 10
	class1msg_len: equ $-class1msg
	
	class2msg db "income < 50k", 10
	class2msg_len: equ $-class2msg
	
	new_line db 10
	new_line_len: equ $-new_line

	space_char db " "
	space_char_len: equ $-space_char
	
	curr_k db 0
	
	selected_rows dw -1,-1,-1,-1,-1 ; = -1 * k, indices of rows selected
	selected_distances dw -1,-1,-1,-1,-1 ; = -1 * k, distances of rows selected
	
	previous_distance dw 0FFFFH ; = minimum distance selected in previous iteration
	
	temp_selected_row dw -1
	
	temp_test_row dw 095,042,011,100,000,000,000,080,100,000,000,000,043,095
	temp_test_row1 dw 095,000,011,040,000,090,000,080,100,000,000,000,043,095
	
	current_row dw 0
	k_counter dw 0
	class1_count db 0
	class2_count db 0

;-----------------------------------------------------

%macro  Print  2
	mov   rax, 1
	mov   rdi, 1
	mov   rsi, %1
	mov   rdx, %2
	syscall
%endmacro

%macro Exit  0
	mov  rax, 60
	mov  rdi, 0
	syscall
%endmacro

%macro ReadRow 3
	mov eax, 0
	mov rdi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro WritePred 3
	mov eax, 1
	mov rdi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro OpenFile 3
	mov eax, 2
	mov rdi, %1
	mov rsi, %2
	mov rdx, %3
	syscall
%endmacro

%macro CloseFile 1
	mov eax, 3
	mov rdi, %1
	syscall
%endmacro

%macro PrintRow 2
	mov rax, %1
	mov rsi, %2
	call printRowProcedure
%endmacro

;-----------------------------------------------------

section .bss
	fd resq 1
	
	buffer resb buffer_len
	train_df resw cols*train_rows
	test_df resw cols*test_rows
	row resb buffer_len
	row_len: equ $-row
	
	predictions_list resw test_rows
	predictionIterator resq 1
	
	row_to_test resq 1
	iterator_counter resw 0

	char_ans resb  8 ; For disp_procedure

section .text
	global _start
_start:
	Print title, title_len
	
	; get train dataset
	OpenFile train_filename, 0, 0
	mov [fd], rax ; save returned file descriptor
	call getDF_train
	call clearRegisters
	CloseFile [fd]
	; PrintRow train_rows-1, train_df
	
	OpenFile test_filename, 0, 0
	mov [fd], rax
	call getDF_test
	call clearRegisters
	CloseFile [fd]
	; PrintRow 200, test_df
	
	call predictions ; use test_row, and calculate knn. fill selected_rows with 0-based indexes, and selected_distances with those corresponding minimum distances

	call Write_results
	; Print new_line, new_line_len
	; Print new_line, new_line_len
	; call Print_result
	; call print_selected_rows
	; call print_selected_distances
	Exit

;-----------------------------------------------------

getDF_train:
	xor r9, r9
	mov r9, train_rows
	mov r10, train_df
	jmp cont3
getDF_test:
	xor r9, r9
	mov r9, test_rows
	mov r10, test_df
cont3:
	ReadRow [fd], buffer, buffer_len
	xor rcx, rcx
	mov cl, cols
	call getRow
	dec r9
	jnz cont3
ret

;-----------------------------------------------------

getRow:
	xor rbx, rbx
	xor rdx, rdx
	mov rsi, buffer
	mov dl, 10
cont1:
	xor rax, rax
	mov r8, data_unit_len
cont2:
	mov bl, [rsi]
	sub bl, 30H
	mul dl
	add al, bl
	inc rsi
	dec r8
	jnz cont2

	mov [r10], ax
	add r10, 2
	inc rsi ; comma ignore
	dec rcx
	jnz cont1
ret

;-----------------------------------------------------

clearRegisters:
	xor rax, rax
	xor rcx, rcx
	xor rdx, rdx
	xor rdi, rdi
	xor rsi, rsi
	xor rbx, rbx
	xor r8, r8
	xor r9, r9
	xor r10, r10
ret

;-----------------------------------------------------

printRowProcedure:
	; address calculation
	mov rbx, 2
	mul rbx
	mov rbx, cols
	mul rbx
	add rsi, rax
	
	mov rdi, row+data_unit_len-1
	mov r8, cols
cont5:
	xor rax, rax
	xor rbx, rbx
	mov ax, [rsi]
	mov rcx, 3
	mov bx, 10
cont4:
	xor rdx, rdx
	div bx
	add dl, 30H
	mov [rdi], dl
	dec rdi
	dec rcx
	jnz cont4
	
	add rsi, 2
	add rdi, data_unit_len+1
	mov byte [rdi], 2CH ; comma
	add rdi, data_unit_len
	dec r8
	jnz cont5
	Print row, row_len
	Print new_line, new_line_len
ret

;----------------------------------------------------- 

disp64_proc:
	mov rbx, 16                 ; divisor=16 for hex
	mov rcx,8 ; number of digits
	mov rsi,char_ans+7        ; load last byte address of char_ans buffer in rsi
cnt:    
	mov rdx,0        ; make rdx=0 (as in div instruction rdx:rax/rbx)
	div rbx
	cmp dl, 09h ; check for remainder in rdx
	jbe add30
	add dl, 07h
add30:
	add dl,30h ; calculate ASCII code
	mov [rsi],dl ; store it in buffer
	dec rsi ; point to one byte back
	dec rcx ; decrement count
	jnz cnt ; if not zero repeat
	Print char_ans,8 ; display result on screen
ret

;-----------------------------------------------------

disp_decimal_proc:
	mov rbx, 10    ; divisor=16 for hex
	mov rcx, 8    ; number of digits
	mov rsi, char_ans+7        ; load last byte address of char_ans buffer in rsi
cnt2:    
	mov rdx,0       ; make rdx=0 (as in div instruction rdx:rax/rbx)
	div rbx
	add dl,30h 		; calculate ASCII code
	mov [rsi],dl 	; store it in buffer
	dec rsi 		; point to one byte back
	dec rcx 		; decrement count
	jnz cnt2 		; if not zero repeat
	Print char_ans, 8 ; display result on screen
ret

;-----------------------------------------------------

calculate_distance:
	; rax contains input/test row
	; rbx contains train df base add
	; rdx contains train row number
	
	imul rdx, 2 ; word length
	imul rdx, cols
	mov rax, qword [row_to_test] ; address of row to test
	mov rbx, train_df
	add rbx, rdx ; add offset to rbx ; address of train row
		;mov ax, [rbx]
		;call disp64_proc
	mov r8, cols-1
	mov r11, 0 ; current_distance
	mov rdx, 0

calculate_distance_up:
	mov rdx, 0
	mov dx, [rax]
	mov r9, rdx
	mov rdx, 0
	mov dx, [rbx]
	cmp r9, rdx ; calculate mod/abs value
	jb calculate_distance_negative
	
calculate_distance_positive:
	sub r9, rdx
	jmp calculate_distance_down
calculate_distance_negative:
	sub rdx, r9
	mov r9, rdx
	jmp calculate_distance_down
	
calculate_distance_down:
	add r11, r9 ; add calculated value to total
	add rax, 2 ; rax is wordptr
	add rbx, 2 ; rbx is wordptr
	dec r8
	jnz calculate_distance_up
	mov r8, r11
	;mov rax, r11
	;call disp64_proc
	;answer stored in r8
ret

;-----------------------------------------------------

calculate_min_distance:
	; rax contains input/test row
	; rbx contains train row frame
	; rcx contains counter
	mov rcx, 0
calculate_min_distance_up:
	mov rdx, rcx ; i th row
	mov r12, 0
	mov r12b, byte [k] ; move k to r12. Now we check if current row is not in selected_rows
	mov r8, selected_rows
	
	; to not repeat indices
calculate_min_distance_up_comparator:
	cmp cx, word [r8] ; compare current row index
	je calculate_min_distance_down ; equal index, so skip index
	add r8, 2
	dec r12
	jnz calculate_min_distance_up_comparator

	call calculate_distance
	mov r12, 0
	mov r12w, word [previous_distance] ; move previous min distance to r12
	mov r9, r8
	cmp r8, r12 ; compare previous distance with current distance
	jae calculate_min_distance_down
	mov word [previous_distance], r9w ; store new min distance
	mov r8, rcx
	mov [temp_selected_row], r8w ; store which row selected

calculate_min_distance_down:
	inc rcx
	cmp rcx, train_rows ; number of rows in train data frame
	jne calculate_min_distance_up

	mov rax, 0
	mov bx, word [previous_distance] ; get min distance
		;call disp64_proc
		;Print new_line, new_line_len
	mov ax, [temp_selected_row] ; get min distance row
		;call disp64_proc
		;Print new_line, new_line_len
ret

;-----------------------------------------------------

calculate_knn:
	mov byte [curr_k], 0
	mov rcx, 0
	mov cl, [k]
	mov rsi, selected_rows

loopback:
	mov word [rsi], -1
	add rsi, 2
	dec rcx
	jnz loopback

calculate_knn_up:
	mov r10, previous_distance
	mov word [r10], 0FFFFH
	call calculate_min_distance

	; calculate address of current selected row & store in it
	mov r10, selected_rows
	mov r11, 0
	add r11b, byte [curr_k]
	imul r11, 2
	add r10, r11
	mov word [r10], ax ; save selected row

	; calculate address of current selected distance & store in it
	mov r10, selected_distances
	mov r11, 0
	add r11b, byte [curr_k]
	imul r11, 2
	add r10, r11
	mov word [r10], bx ; save selected distance

	mov r10, 0
	mov r10b, byte [curr_k]
	inc r10
	mov byte [curr_k], r10b

		; mov rax, r10
		;call disp64_proc
		;Print new_line, new_line_len
		;call print_selected_rows
		;Print haad,  haad_len
		;call print_selected_distances
		
	mov r10b, byte [curr_k]
	cmp r10b, byte [k]
	jne calculate_knn_up
	;Print new_line, new_line_len
ret

;-----------------------------------------------------

print_selected_rows:
	;Print new_line, new_line_len
	mov r10b, byte [k]
	mov r9, selected_rows
print_selected_rows_up:
	mov rax, 0
	mov ax, word [r9]
	call disp64_proc
	add r9, 2
	Print space_char, space_char_len
	dec r10
	jnz print_selected_rows_up
	Print new_line, new_line_len
ret

;-----------------------------------------------------

print_selected_distances:
	mov r10b, byte [k]
	mov r9, selected_distances
	print_selected_distances_up:
	mov rax, 0
	mov ax, word [r9]
	call disp64_proc
	add r9, 2
	Print space_char, space_char_len
	dec r10
	jnz print_selected_distances_up
	Print new_line, new_line_len
ret

;-----------------------------------------------------

predictions:
	mov qword [predictionIterator], predictions_list
	mov word [current_row], 0
	mov word [iterator_counter], test_rows  ; number of rows
back:
		; calculation of base address of row in row_to_test

	mov qword [row_to_test], test_df
	xor r11, r11
	mov r11, cols
	imul r11, 2
	imul r11w , word [current_row]
	add qword [row_to_test], r11
	
		;mov r8, qword [row_to_test]
		;mov ax, word [r8]
		;call disp_decimal_proc
		;Print new_line, new_line_len
	
	call calculate_knn
	
		;call print_selected_rows
	
	call predict_class
	
	inc word [current_row]
	dec word [iterator_counter]
	cmp word [iterator_counter], 0
	jne back
	
		;CloseFile OpenFile test_output_filename, 0, 0
ret

;-----------------------------------------------------

predict_class:
	mov byte [k_counter], 0
	mov byte [class1_count], 0
	mov byte [class2_count], 0
next_neighbor:
	mov r11, selected_rows
	xor rax, rax
	mov al, byte [k_counter]
	imul rax, 2
	add r11, rax
	mov r8, train_df
	mov r10, cols
	imul r10, 2
	xor rax, rax
	mov ax, word [r11]
	inc ax
	imul r10, rax
	add r8, r10
	sub r8, 2
	;mov ax, word [r8]
	;call disp_decimal_proc
	;Print new_line, new_line_len
	cmp word [r8], 100
	je skip
	inc byte [class2_count]
	jmp next
skip:
	inc byte [class1_count]
next:
	inc byte  [k_counter]
	cmp byte [k_counter], 5
	jnz next_neighbor
	mov al, byte [class1_count]
	cmp al, byte [class2_count]
	jg class1
	mov rax, [predictionIterator]
	mov word [rax] , 0
	xor r9, r9
	mov r9, qword [predictionIterator]
	;xor rax, rax
	;mov ax, word [r9]
	;call disp_decimal_proc
	add qword [predictionIterator], 2
	xor rax, rax
	mov al, byte [class2_count]
	;call disp64_proc
	;Print class2msg, class2msg_len
ret

class1:
	mov rax, [predictionIterator]
	mov word [rax] , 100
	xor r9, r9
	mov r9, qword[predictionIterator]
	;xor rax, rax
	;mov ax, word [r9]
	;call disp_decimal_proc
	add qword [predictionIterator], 2
	xor rax, rax
	mov al, byte [class1_count]
	;call disp64_proc
	;Print class1msg, class1msg_len
ret

;--------------------------------------------------------------

Print_result:
	mov r9, predictions_list
	mov r10, test_rows
next_pred1:
	xor rax, rax
	mov ax, word [r9]
	call disp_decimal_proc
	Print new_line, new_line_len
	add r9,2
	dec r10
	jnz next_pred1
ret

Write_results:
	mov r9, predictions_list
	mov r10, test_rows
	OpenFile output_filename, 577, 0644
	mov [fd], rax

next_pred2:	
	xor rax, rax
	xor cx, cx
	mov rbx, 10
	mov ax, [r9]
	mov cx, 3
	mov rdi, char_ans+data_unit_len-1
cont6:
	xor rdx, rdx
	div rbx
	add dl, 30H
	mov [rdi], dl
	dec rdi
	dec cx
	jnz cont6
	
	mov al, 10
	mov rdi, char_ans
	add rdi, 3
	mov [rdi], al
	WritePred [fd], char_ans, 4
	WritePred [fd], new_line, new_line_len
	add r9, 2
	dec r10
	jnz next_pred2
	CloseFile [fd]
ret
