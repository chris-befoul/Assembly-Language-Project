TITLE Designing low-level I/O procedures    (Proj6_hardisoc.asm)

; ; Author: Chris Hardison
; Last Modified:	3/12/2021
; OSU email address: hardisoc@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:       6          Due Date:	3/14/2021 
; Description: A program using macros to complete I/O procedures utilzing string primitives. The user inputs
;				ten signed integers which are read by a macro call and put into an array which is then outputted
;				along with the sum an average using a macro call. 

INCLUDE Irvine32.INC


; ---------------------------------------------------------------------------------
; Name: mGetString
;
; Utilizes ReadString to obtain input from user.
;
; Preconditions: None
;
; Receives:
; prompt = string primitive
; count = SIZEOF prompt
;
; returns: 
; prompt = ReadString from user
; count	=  SIZEOF prompt
; ---------------------------------------------------------------------------------
mGetString	MACRO prompt, count	
	PUSH		EDX
	PUSH		ECX
	MOV			EDX, prompt
	MOV			ECX, count
	CALL 		ReadString
	POP			ECX
	POP			EDX
ENDM

; ---------------------------------------------------------------------------------
; Name: mDisplayString
;
; Utilizes WriteString to output input from user to console.
;
; Preconditions: Valid input from user
;
; Receives:
; string_num = string primitive of signed integer
;
; Returns: 
; None
; ---------------------------------------------------------------------------------
mDisplayString	MACRO	string_num
	PUSH		EDX
	MOV			EDX, string_num
	CALL		WriteString
	POP			EDX
ENDM

; Constants
	user_count = 10					; Represents the number of possible valid inputs by user

.data

	title_prompt			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O procedures",0
	author_prompt			BYTE	"Written by: Chris Hardison",0
	rules1					BYTE	"Please provide 10 signed decimal integers.",0
	rules2					BYTE	"Each number needs to be small enough to fit inside a 32 bit register.",0
	rules3					BYTE	"After you have finished inputting the raw numbers I will display",0
	rules4					BYTE	"a list of the integers, their sum, and their average value.",0
	user_prompt				BYTE	"Please enter a signed number: ", 0
	error_prompt			BYTE	"ERROR: You did not enter a signed number or your number was too big.",0
	retry_prompt			BYTE	"Please try again: ",0
	list_prompt				BYTE	"You entered the following numbers:",0
	num_seperate			BYTE	", ", 0
	sum_prompt				BYTE	"The sum of these numbers is: ",0
	average_prompt			BYTE	"The average is: ",0
	farewell				BYTE	"Thanks for playing!",0
	user_numbers			SDWORD	10 DUP(0)					
	user_sum				SDWORD	?							; Represents the sum of valid inputs
	user_average			SDWORD	?							; Represents the average of valid inputs
	user_string				BYTE	255 DUP (0)
	user_temp				BYTE	32 DUP (?)

.code
main PROC

; Print title, author, and rules to console
	mDisplayString	OFFSET title_prompt
	CALL		CrLf
	mDisplayString	OFFSET author_prompt
	CALL		CrLf
	CALL		CrLf
	mDisplayString	OFFSET rules1
	CALL		CrLf
	mDisplayString	OFFSET rules2
	CALL		CrLf
	mDisplayString	OFFSET rules3
	CALL		CrLf
	mDisplayString	OFFSET rules4
	CALL		CrLf
	CALL		CrLf

; Sets registers for prompt_user LOOP
	MOV			ECX, user_count
	MOV			EDI, OFFSET user_numbers

; Prompt the user for signed integer input
prompt_user:

	mDisplayString	OFFSET user_prompt

; Push address (prompt) of user_string onto the stack to be used in ReadVal procedure
	PUSH		OFFSET retry_prompt
	PUSH		OFFSET error_prompt
	PUSH		OFFSET user_string
	PUSH		SIZEOF user_string
	CALL		ReadVal

; Iterate to the next slot in the array
	MOV			EAX, SDWORD PTR user_string
	MOV			[EDI], EAX
	ADD			EDI, 4									

; Continue prompt_user LOOP if inputs < user_count
	LOOP		prompt_user
	CALL		CrLf

; Set registers for sum_finder LOOP
	MOV			ECX, user_count
	MOV			ESI, OFFSET user_numbers
	MOV			EBX, 0					

; Print to console list_prompt using mDisplayString macro
	mDisplayString	OFFSET list_prompt
	CALL		CrLf

; Calculate the user_sum and output the number to the user
sum_finder:
	MOV			EAX, [ESI]
	ADD			EBX, EAX				; Adding number in EAX to user_sum total in EBX

; Push parameters in EAX and in user_temp onto the stack to be used in WriteVal procedure
	PUSH		EAX
	PUSH		OFFSET user_temp
	CALL		WriteVal
	CMP			ECX, 1					; Checking to see if the last number will be printed
	JE			last_input
	mDisplayString	OFFSET num_seperate

last_input:

	ADD			ESI, 4					; Iterate to the next number
	LOOP		sum_finder
	CALL		CrLf

; Output the user_sum to the user
	MOV			EAX, EBX
	MOV			user_sum, EAX
	mDisplayString	OFFSET sum_prompt

; Push user_sum and user_temp onto the stack to be utilized by WriteVal procedure
	PUSH		user_sum
	PUSH		OFFSET user_temp
	CALL		WriteVal
	CALL		CrLf
	
; Set EDX to zero and set EBX to user_count to be utilzied for calculating user_average
	MOV			EBX, user_count
	MOV			EDX, 0
	CDQ

; Divide the user_sum by user_count (using IDIV to allow for signed integers) to calculate user_average
	IDIV		EBX
	MOV			user_average, EAX
	mDisplayString	OFFSET average_prompt

; Push parameters user_average and user_temp onto the stack to be used by WriteVal
	PUSH		user_average
	PUSH		OFFSET user_temp
	CALL		WriteVal
	CALL		CrLf
	CALL		CrLf
	
; Display goodbye message
	mDisplayString	OFFSET farewell
	CALL		CrLf

	exit		; exit to operating system
main ENDP


; ---------------------------------------------------------------------------------
; Name: ReadVal
;
; Used to obtain valid signed integer inputs from user utilzing mGetString macro.
;
; Preconditions: none
;
; Postconditions: Changes user_string
;
; Receives:
; [ebp+20] = retry_prompt
; [ebp+16] = error_prompt
; [ebp+12] = user_string
; [ebp+8] = SIZEOF user_string
; sign_holder is a local variable used to represent if valid input is negative or positive
;
; returns: user_string
; ---------------------------------------------------------------------------------
ReadVal PROC
	LOCAL sign_holder:SDWORD

	PUSH		EBP
	MOV			EBP, ESP

	PUSHAD											; Push 32 bit register onto stack
	ADD			EBP, 8

initialize:
	MOV			EDX, [EBP + 12]							; Assign user_string to EDX
	MOV			ECX, [EBP + 8]							; Assign SIZEOF user_string to ECX

; Read the input from the user using mGetString macro
	mGetString	EDX, ECX
	CMP			EAX, 0								; Checks if user did not input anything
	JE			_invalid

; Initialize the registers
	MOV			ESI, EDX
	MOV			EAX, 0
	MOV			ECX, 0

; Load the string one by one
start:
	LODSB											; loads from memory at ESI
	CMP			AX, 0									; Check if end string has been reached
	JE			last_step
	MOV			EBX, EDX
	INC			EBX
	CMP			ESI, EBX
	JE			sign_check

; Check if input is a digit in ASCII
validate:
	CMP			AX, 48				; ASCII code 48 represents zero (0) digit
	JL			_invalid
	CMP			AX, 57				; ASCII code 57 represents nine (9) digit
	JG			_invalid

; Convert ASCII value to corresponding digit
	MOV			EBX, 10
	SUB			AX, 48
	XCHG		EAX, ECX
	IMUL		EBX					; multiply by 10 for correct digit place
	JC			_invalid
	JNC			_valid

; Verify if input is either positive or negative
sign_check:
	CMP			AX, 45				; ASCII code 45 represents minus/negative sign
	JE			negative
	MOV			sign_holder, 0
	JG			validate
	

	CMP			AX, 43				; ASCII code 43 represents plus/positive sign
	JL			_invalid
	JE			positive

	CMP			AX, 44				; Checks if value falls between positive and negative characters
	JE			_invalid

; Set sign_holder local variable to one to represent negative number
negative:
	MOV			sign_holder, 1
	JMP			start
	
; Sets sign_holder local variable to zero to represent positive number
positive:
	MOV			sign_holder, 0
	JMP			start

; User has inputed invalid entry
_invalid:
	MOV			EDX, [EBP +16]		; Assigns error_prompt to EDX
	mDisplayString	EDX
	CALL		CrLf
	MOV			EDX, [EBP + 20]		; Assigns retry_prompt to EDX
	mDisplayString	EDX

	JMP			initialize

; ASCII code is a valid digit/positive/negative 
_valid:
	ADD			EAX, ECX
	XCHG		EAX, ECX			; Exchange references in EAX and ECX
	JMP			start				; Move to next character/ASCII code
	

last_step:
	XCHG		ECX, EAX			; Exchange references in ECX and EAX
	CMP			sign_holder, 1		; Check if input is negative
	JE			neg_num
	JMP			finished

neg_num:
	NEG			EAX					; Convert number to negative value

finished:
	MOV			SDWORD PTR user_string, EAX		; Save int in passed variable
	POPAD									; Pop 32 bit register from stack
	POP EBP

	RET 20

ReadVal ENDP


; ---------------------------------------------------------------------------------
; Name: WriteVal
;
; Uses macro mDisplayString to print signed integer to console.
;
; Preconditions: Integer values.
;
; Postconditions: none.
;
; Receives:
; [ebp+12] = value to be writtent to console
; [ebp+8] = user_temp
; Local variable place_holder used for negative validation
;
; returns: none
; ---------------------------------------------------------------------------------
WriteVal PROC
	LOCAL	place_holder:SDWORD
	
	PUSH		EBP
	MOV			EBP, ESP
	PUSHAD											; Push 32 bit register onto stack

; Sets registers to begin "stringify" process
	ADD			EBP, 8
	MOV			EAX, [EBP + 12]							; Assign signed integer value to EAX
	MOV			EDI, [EBP + 8]							; Assigne user_temp to EDI to store string
	MOV			EBX, 10
	PUSH		0
	TEST		EAX, EAX								; Checks if signed integer is a negative value
	JS			neg_num
	JMP			stringify

; Finds ASCII code for value
stringify:
	MOV			EDX, 0
	IDIV		EBX
	ADD			EDX, 48
	PUSH		EDX

	CMP			EAX, 0									; Checks if last digit in value has been processed
	JNE			stringify
	JE			convert_neg

; POP values/ASCII codes off the stack
next_num:

	POP			[EDI]
	MOV			EAX, [EDI]
	INC			EDI
	CMP			EAX, 0									; Check if last value has been popped
	JNE			next_num

; Print to console as string using the macro mDisplayString
	MOV			EDX, [EBP + 8]
	mDisplayString	EDX

	POPAD											; POP 32 bit register from stack
	POP			EBP

	RET 12

; PUSHes ASCII code 45 onto stack if number is negative
convert_neg:
	CMP			place_holder, 45
	JNE			next_num
	MOV			EDX, place_holder
	PUSH		EDX
	JMP			next_num

; Changes value/signed integer to a negative number
neg_num:
	NEG			EAX
	MOV			place_holder, 45
	JMP			stringify

WriteVal ENDP

END main