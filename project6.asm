TITLE Project 6     (project6.asm)

; Author: William E Roberts
; Last Modified: 3/12/2022
; OSU email address: robertw5@oregonstate.edu
; Course number/section:   CS271 Section 400
; Project Number:      6           Due Date:   3/13/2022
; Description: 10 signed numbers are entered by user and stored as a string, able to fit into 32 bit register. These numbers are first 
; converted from their asc2 values into numerical values and stored into an array, then from numerical back to asc2value. This asc2 value
; is then printed as a string, all 10 numbers entered by user, total sum displayed (able to fit within 32 bit reg)
; and truncated avg displayed (integer only, no rounding)


INCLUDE Irvine32.inc


;-----------------------------------------------------------------------
;Name: mGetString
;
;Prints an input prompt and stores user input as string
;
;Preconditions: dont use ecx, edx, eax as arguments
;
;Receives: 
;prompt = prompt to be printed
;input = string where users input is stored
;size = where number of characters user entered is stored
;
;Returns: input = where users input stored, size = numb characters user entered
;-----------------------------------------------------------------------
mGetString	MACRO	prompt, input, size
	PUSH	ECX
	PUSH	EDX
	PUSH	EAX
	MOV		EDX, prompt					;prints passed in prompt
	CALL	WriteString
	
	MOV		EDX, input					;users input stored here after calling readstring
	MOV		ECX, 33
	CALL	ReadString
	MOV		size, EAX					;number of characters user entered stored here
	POP		EAX
	POP		EDX
	POP		ECX
ENDM



;------------------------------------------------------------------------
;Name: mDisplayString
;
;Prints string that was passed in as argument
;
;Precond: Dont pass in edx
;
;Receives: inputString = any string desired to be printed
;
;Returns: inputString is displayed to console
mDisplayString	MACRO	inputString
	PUSH  EDX				
	MOV   EDX,	inputString
	CALL  WriteString
	POP   EDX				
ENDM



.data
	prompt1			BYTE	" Enter 10 signed decimal integers, each number able to fit in a 32 bit register. ",10,13,
							" These numbers will then be displayed, as well as their sum and avg value",10,13,0
	prompt2			BYTE	" Enter a signed number: ",0
	invalidMsg		BYTE	" Not a signed number or number too big!",10,13,0
	userString		BYTE	33	DUP (0)					;users input stored here
	stringSize		DWORD	?							;# of characters user entered
	ascToNumber		BYTE	?
	numbersArray	SDWORD	10 DUP (?)					;holds asc2 to number converted values
	setInvalid		DWORD	?
	isNegative		DWORD	0
	numberToAsc		BYTE	33	DUP (0)					;number converted to asc (string) for printing
	tempAscHolder	DWORD	?							;holds temp converted value before put into string
	numDigits		DWORD	?
	commaSpace		BYTE	", ",0
	displayTitle	BYTE	" List of Signed Numbers: ",10,13,0
	sumNumbers		SDWORD	?								;sum of all numbers entered
	sumString		BYTE	33	DUP (0)						;sum converted to string for printing 
	sumTitle		BYTE	" Sum of Numbers: ",0
	avgNumbers		SDWORD	?								;avg of numbers entered
	avgTitle		BYTE	" Truncated Avg: ",0
	avgString		BYTE	33	DUP (0)						;avg converted to string for printing

.code
main PROC
	mDisplayString	OFFSET	prompt1						;program title, directions etc
	CALL	CrLf
	
	;preps registers to get users input
	PUSH	ESI
	PUSH	ECX
	MOV		ECX, 10							;counter 10 bec 10 # entered from user
	MOV		ESI, OFFSET	numbersArray		;pointer to array that will hold asc2 to number values
_getInput:
	PUSH	OFFSET	isNegative				;1 if number negative, 0 otherwise
	PUSH	ESI								;mem location at particular index of numbersarray
	PUSH	OFFSET	stringSize
	PUSH	OFFSET	prompt2					;asks user to enter number
	PUSH	OFFSET	invalidMsg
	PUSH	OFFSET	setInvalid				;1 if invalid, 0 otherwise
	PUSH	OFFSET	ascToNumber				;holds asc to number converted value then placed into array
	PUSH	OFFSET	userString				;users input
	CALL	readValue						
	CMP		setInvalid, 1					;input was invalid, getinput again asking for another entry
	JE		_getInput
	ADD		ESI, 4							;valid entry, points to next mem location in numbers array
	LOOP	_getInput						;new entry if less than 10 valid entries
	POP		ECX
	POP		ESI

	;converts from numerical value to asc2 then prints string
	PUSH	ESI
	PUSH	ECX
	MOV		ESI, OFFSET	numbersArray		;holds asc2 to number values
	MOV		ECX, 10							;10 entries need to be displayed
	CALL	CrLf
	mDisplayString	OFFSET	displayTitle	;macro to display strings, displaytitle to list all input
_printVal:
	PUSH	OFFSET	numDigits				;# digits of current entry
	PUSH	OFFSET	tempAscHolder
	PUSH	OFFSET	numberToAsc				;converted string to be printed
	PUSH	[ESI]							;value in array
	CALL	writeValue
	CMP		ECX, 1							;last elem
	JE		_lastElemDisplay				
	mDisplayString	OFFSET	commaSpace			;prints , space between each elem
;prints last elem without , space
_lastElemDisplay:
	ADD		ESI, 4
	LOOP	_printVal
	POP		ECX
	POP		ESI
	CALL	CrLf

	;calcs sum of entries
	PUSH	OFFSET	sumNumbers
	PUSH	OFFSET	numbersArray
	CALL	sumCalc

	;calcs avg of entries
	PUSH	OFFSET	sumNumbers
	PUSH	OFFSET	avgNumbers
	CALL	avgCalc

	;prints sum 
	PUSH	ESI
	MOV		ESI, OFFSET	sumNumbers
	mDisplayString	OFFSET	sumTitle
	PUSH	OFFSET	numDigits
	PUSH	OFFSET	tempAscHolder
	PUSH	OFFSET	sumString			;converted value to asc2 string to be printed
	PUSH	[ESI]						;pushes value and not mem location as writevalue reqs
	CALL	writeValue
	CALL	CrLf
	POP		ESI

	;prints avg
	PUSH	ESI
	MOV		ESI, OFFSET	avgNumbers
	mDisplayString	OFFSET	avgTitle
	PUSH	OFFSET	numDigits
	PUSH	OFFSET	tempAscHolder
	PUSH	OFFSET	avgString
	PUSH	[ESI]
	CALL	writeValue
	CALL	CrLf
	POP		ESI
	INVOKE ExitProcess, 0

main ENDP



;------------------------------------------------------------------------
;Name: readValue
;
;Gets single input as string of digits, validates its a number, 
;converts from asc2 to numerical value, then stores into array
;
;Precond: user must enter numbers only when prompted, array to be saved must be sdword,
;			array where converted value stored passed in by reference, isnegative, stringsize, prompt2,
;			invalidmsg, setinvalid, asctonumber, userstring all required or their datatype equivalents
;
;Postcond: none
;
;Receives: [ebp + 8] = string to hold input 
;			[ebp + 12] = holds converted asc2 value
;			[ebp + 16] = validity of entry status
;			[ebp + 20] = invalid msg
;			[ebp + 24] = prompts user for entry
;			[ebp + 28] = size of string
;			[ebp + 32] = array to hold converted asc2 value
;			[ebp + 36] = sign status of entry
;
;Returns: [edi] = converted asc2 value into number stored in array
;-----------------------------------------------------------------------
readValue PROC	
	PUSH	EBP
	MOV		EBP, ESP
	
	PUSH	EDX
	PUSH	EAX
	PUSH	ESI
	PUSH	EDI
	PUSH	EBX
	PUSH	ECX

	;calls on macro to get single user entry, passing in entry prompt, string to hold input and variable to hold string size
	mGetString	[EBP + 24], [EBP + 8], [EBP + 28]
	
	CLD									;left to right
	MOV		ESI, [EBP + 8]				;input string
	MOV		EDI, [EBP + 12]				;converted value
	MOV		ECX, [EBP + 28]				;# of characters entered thus how many string bytes need converting

	CMP		ECX, 11
	JG		_setInvalid	
	
	MOV		EDX, 0						;stores converted value itself as each digit x 10 and added to edx
;converts asc to number, the length of input string
_ascToNumber:
	DEC		ECX
	LODSB							;loads esi into al
	CMP		ECX, 10					;if max chars entered w/ - or + 
	JE		_leadingSignCheck

	;if + or -
	CMP		AL, 43
	JE		_ascToNumber
	CMP		AL, 45
	JE		_setNegativeCheck

	;subtracts asc2 value by 48 to get #, if non-number then sets invalid
	SUB		AL, 48
	CMP		AL, 9
	JG		_setInvalid
	CMP		AL, 0
	JL		_setInvalid

	;digit valid, x by 10 and added to cumulative total
	MOVSX	EBX, AL						;different sized registers
	IMUL	EDX, 10
	JO		_setInvalid					;overflow for 32 bit register
	ADD		EDX, EBX
	JMP		_endStringCheck
	
;checks if leading digit is + or - when max characters entered (11)
_leadingSignCheck:
	CMP		AL, 43						; + 
	JE		_ascToNumber
	CMP		AL, 45						; - 
	JE		_setNegativeCheck
	JMP		_setInvalid					

;sets entry as invalid status for main proc
_setInvalid:
	MOV		EDX, [EBP + 20]				;invalid msg
	MOV		EAX, [EBP + 16]				;validity status
	MOV		EBX, 1
	MOV		[EAX], EBX
	CALL	WriteString
	JMP		_resetNegativeStatus

;checks if end of input string reached
_endStringCheck:
	CMP		ECX, 0
	JE		_setValid
	JMP		_ascToNumber			;continue conversion
	
;checks sign status of current entry
_setNegativeCheck:
	PUSH	EAX
	PUSH	EBX
	MOV		EAX, [EBP + 36]				;sign status
	MOV		EBX, [EAX]
	CMP		EBX, 0
	JE		_setNegative
	POP		EBX
	POP		EAX
	JMP		_setInvalid				;# already set as - thus - sign not leading

;sets sign status of current entry as -
_setNegative:
	POP		EBX
	POP		EAX
	PUSH	EAX
	PUSH	EBX
	MOV		EAX, [EBP + 36]			;sign status
	MOV		EBX, 1
	MOV		[EAX], EBX
	POP		EBX
	POP		EAX
	JMP		_ascToNumber			;continues conversion

;sets current entry as valid for main proc purposes
_setValid:
	MOV		EAX, [EBP + 16]				;validity status of current entry
	MOV		EBX, 0
	MOV		[EAX], EBX

;checks if current entry is negative
_isNegativeCheck:
	MOV		EAX, [EBP + 36]					;sign status of current entry
	MOV		EBX, [EAX]
	CMP		EBX, 1
	JE		_addNegativeSign
	JMP		_storeValueInArray

;multiply converted value by -1 if entry was originally negative
_addNegativeSign:
	IMUL	EDX, -1
	
;stores converted value into numbersarray
_storeValueInArray:
	MOV		EDI, [EBP + 32]			;numbersarray 
	MOV		[EDI], EDX

;resets sign status after converted current entry added to array
_resetNegativeStatus:
	PUSH	EAX
	PUSH	EBX
	MOV		EAX, [EBP + 36]
	MOV		EBX, 0
	MOV		[EAX], EBX
	POP		EBX
	POP		EAX

_end:
	POP		ECX
	POP		EBX
	POP		EDI
	POP		ESI
	POP		EAX
	POP		EDX
	POP		EBP
	RET		32
readValue ENDP



;-------------------------------------------------------------------------------------
;Name:	writeValue
;
;Takes a numerical value and converts it into asc2 then prints the asc2 string
;
;Precond: number to be converted to asc2 must be passed in by value, commaspace must be passed in,
;         as well as numdigits, tempascholder and numbertoasc (or their data type equivalents)
;
;Postcond:	none
;
;Receives: [ebp + 8] = value from array to be converted to asc2
;			[ebp + 12] = converted val to be printed
;			[ebp + 16] = temp asc holder
;			[ebp + 20] = number of digits of value
;
;Returns: [ebp + 12] = prints converted value to asc2 string
;---------------------------------------------------------------------------------------
writeValue	PROC
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	ESI
	PUSH	EAX
	PUSH	EDX
	PUSH	EBX
	PUSH	ECX
	PUSH	EDI

	CLD							;left to right
	MOV		ESI, [EBP + 8]		;value from array to be converted
	MOV		EDI, [EBP + 12]		;converted val to be printed
	MOV		EBX, 10				;used to find # digits of value
	MOV		EAX, ESI

	;value now in eax, finds if # is - or otherwise
	MOV		ECX, 0
	CMP		EAX, 0
	JL		_negativeToPositive
	JMP		_init					;initialize for conversion

;converts val to positive, - sign will be added as asc2 value at end, inc ecx for digit counter
_negativeToPositive:
	IMUL	EAX, -1
	INC		ECX
	
;initializes val preserving its contents while val is modified below
_init:
	PUSH	EAX
	PUSH	EDX

;finds # of digits of val
_findNumberDigits:
	INC		ECX					;digit found
	MOV		EDX, 0				;resets remainder each time
	DIV		EBX					;ebx still 10, eax / ebx = val / 10
	CMP		EAX, 0				;when quotient 0 last digit has been found
	JE		_digitsFound
	JMP		_findNumberDigits

;stores # of digits into variable
_digitsFound:
	PUSH	EBX
	MOV		EBX, [EBP + 20]		;# of digits of current val
	MOV		[EBX], ECX
	POP		EBX
	POP		EDX
	POP		EAX


	STD							;right to left
	ADD		EDI, ECX			;pointer set to end of string, offset by length of val
	DEC		EDI
	CMP		ECX, 1				;val was single 0
	JE		_addSingleZero

;loop responsible for conversion, val = eax, divided by 10, remainder converted to asc2. Stored right to left
_numberToAsc:
	CMP		EAX, 0
	JE		_addNegativeSign		;- sign added if val = 0 after /10 loop below
_addSingleZero:						;val is 0
	MOV		EDX, 0					;edx will hold converted asc2 value
	DIV		EBX						;ebx = 10, value of val after division = eax
	ADD		EDX, 48					;converts current digit of val into asc2
_signAdded:
	MOV		ESI, [EBP + 16]			;temp asc2 holder
	MOV		[ESI], EDX				;converted asc2 value 
	PUSH	EAX
	LODSB							;loads into al mem location at esi, dec esi by 1
	STOSB							;stores al into edi, dec edi by 1 (std direction set)
	POP		EAX
	LOOP	_numberToAsc			;more digits of val need to be converted, val (eax) has been updated
	JMP		_display				;all digits of val converted

;edx converted to asc2 value, - sign added to beginning of string to be printed
_addNegativeSign:
	MOV		EDX, 45
	JMP		_signAdded

;prints converted string
_display:
	mDisplayString	[EBP + 12]		;converted val

	;# digits current val needed to reset temp asc holder
	MOV		EBX, [EBP + 20]			;# digits of current val
	MOV		ECX, [EBX]
	INC		EDI						;points to beginning of string to be printed for next val purposes
	CLD								;left to right

;resets tempasc holder for next val that is called, ecx = length of current val
_resetAscString:
	MOV		ESI, [EBP + 16]
	MOV		EBX, 0
	MOV		[ESI], EBX
	LODSB
	STOSB
	LOOP	_resetAscString
	
_end:
	POP		EDI
	POP		ECX
	POP		EBX
	POP		EDX
	POP		EAX
	POP		ESI
	POP		EBP
	RET		16
writeValue ENDP



;-----------------------------------------------------------------------------------
;Name: sumCalc
;
;Calculates sum of passed in array
;
;Precond: passed in array by reference, must be 10 elements, sumnumbers and numbersarray 
;			must be sdword
;
;Postcond: none
;
;Receives: [ebp + 8] = array of 10 with numbers
;			[ebp + 12] = to store sum
;
;Returns:	[edi]  = sum of passed in array
;-----------------------------------------------------------------------------------
sumCalc		PROC
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	ECX
	PUSH	EAX
	PUSH	ESI
	PUSH	EDI
	PUSH	EBX

	MOV		EBX, 0
	MOV		ESI, [EBP + 8]				;array with numbers
	MOV		EDI, [EBP + 12]				;mem loc where sum will be stored

	MOV		ECX, 10						;passed in array must have 10 elems...
_findSum:
	MOV		EAX, [ESI]					;eax stores each elem, ebx is cumulative total
	ADD		EBX, EAX
	ADD		ESI, 4						;next elem in array
	LOOP	_findSum

	MOV		[EDI], EBX					;stores total into sum mem loc

	POP		EBX
	POP		EDI
	POP		ESI
	POP		EAX
	POP		ECX
	POP		EBP
	RET		8
sumCalc		ENDP



;------------------------------------------------------------------------------------
;Name: avgCalc
;
;calculates avg of passed in number (by ref)
;
;Precond: number passed in by ref must be number and of sdword type. Avg variable must be sdword type
;
;Postcond: none
;
;Receives: [ebp + 8] = variable to store avg of numbers
;			[ebp + 12] = sum of numbers
;
;Returns: [edi] = avg of numbers
;----------------------------------------------------------------------------------
avgCalc		PROC
	PUSH	EBP
	MOV		EBP, ESP

	PUSH	EDI
	PUSH	ESI
	PUSH	EBX
	PUSH	EAX

	MOV		EDI, [EBP + 8]				;variable to store avg of numbers
	MOV		ESI, [EBP + 12]				;sum of numbers
	MOV		EBX, 10						;expected sum had 10 numbers...

	;eax contains sum, divides by # elems giving avg (eax)
	MOV		EAX, [ESI]
	CDQ	
	IDIV	EBX

	MOV		[EDI], EAX					;moves avg into variable to store it

	POP		EAX
	POP		EBX
	POP		ESI
	POP		EDI
	POP		EBP
	RET		8

avgCalc		ENDP

END main
