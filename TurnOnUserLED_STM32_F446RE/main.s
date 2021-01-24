Stack_Size      EQU     0x00000400
                AREA    STACK, NOINIT, READWRITE, ALIGN=3
Stack_Mem       SPACE   Stack_Size
__initial_sp


Heap_Size       EQU     0x00000200
                AREA    HEAP, NOINIT, READWRITE, ALIGN=3
__heap_base
Heap_Mem        SPACE   Heap_Size
__heap_limit

                PRESERVE8
                THUMB


; Vector Table Mapped to Address 0 at Reset
                AREA    RESET, DATA, READONLY
                EXPORT  __Vectors
                EXPORT  __Vectors_End
                EXPORT  __Vectors_Size

__Vectors       DCD     __initial_sp               ; Top of Stack
                DCD     Reset_Handler              ; Reset Handler  
__Vectors_End

__Vectors_Size  EQU  __Vectors_End - __Vectors


; Enable clock access to GPIO peripheral because of clock gate
; https://en.wikipedia.org/wiki/Clock_gating
; pg. 16 DS Figure 3. STM32F446xC/E block diagram
; For ARM Cortex M arhitecture we have two types of peripheral buses:
; APB: Advanced Peripheral Bus
; AHB: Advanced High Performance Bus (faster access)
; pg. 67 DS Figure 15. Memory map also see Table 12. STM32F446xC/E register boundary addresses

RCC_BASEADDRESS 		EQU 0x40023800 ; 0x4002 3800 RCC base address, all registers for RCC config will be an offset from this address
; pg. 143 RM
RCC_AHB1ENR_OFFSET 		EQU 0x30
RCC_AHB1ENR				EQU (RCC_BASEADDRESS + RCC_AHB1ENR_OFFSET)
GPIOAEN 				EQU (1 << 0) ; 0b0000 0000 0000 0000 0000 0000 0000 0001

; Note: Make sure to set data register (in STM uC we have two data ODR and IDR) and direction register (mode regiser for STM uC) for GPIO
; According to schematics the user green led is connected to PA5 pin of uC, pg. 4 Sch
; Set the PORT and LED PIN to output

GPIOA_BASEADDRESS		EQU 0x40020000 ; 0x4002 0000 GPIOA base address, all registers for GPIOA config will be an offset from this address
; pg. 186 RM
GPIOX_MODER_OFFSET 		EQU 0x00
GPIOA_MODER				EQU (GPIOA_BASEADDRESS + GPIOX_MODER_OFFSET)
GPIOA_MODER5_OUT 		EQU (1 << 10) ; 0b0000 0000 0000 0000 0000 0100 0000 0000

; Write value to LED PIN
; pg. 189 RM
GPIOX_ODR_OFFSET 		EQU 0x14
GPIOA_ODR				EQU (GPIOA_BASEADDRESS + GPIOX_ODR_OFFSET)
LED_ON					EQU 0 ; (1 << 5) ; 0b0000 0000 0000 0000 0000 0000 0010 0000

	AREA |.text|, CODE, READONLY, ALIGN = 2
	THUMB ; use thumb instruction set
	ENTRY ; entry point
	EXPORT  Reset_Handler             [WEAK]
	EXPORT __main ; where program starts, export the function name

; Label creation
Reset_Handler
__main
	BL System_Init ; Branch with Link. 
	; The BL instruction causes a branch to label, and copies the address of the next instruction into LR
	
loop
	BL	Turn_On_LED
	B	loop ; branch to same label
	

System_Init
	LDR R0, =RCC_AHB1ENR ; loads the value of address RCC_AHB1ENR into R0
	LDR	R1, [R0] ; loads R1 from the address in R0. Get contents found at address R0 in R1
	ORR R1, R1, #GPIOAEN ; R1 = R1 | GPIOAEN
	STR	R1, [R0] ; contents of R1 stored in RCC_AHB1ENR
	
	LDR R0, =GPIOA_MODER ; loads the value of address GPIOA_MODER into R0
	LDR	R1, [R0] ; loads R1 from the address in R0. Get contents found at address R0 in R1
	ORR R1, R1, #GPIOA_MODER5_OUT ; R1 = R1 | GPIOA_MODER5_OUT
	STR	R1, [R0] ; contents of R1 stored in GPIOA_MODER

	BX LR ; end sub routine
	ALIGN
		
Turn_On_LED
	LDR R0, =GPIOA_ODR ; loads the value of address GPIOA_ODR into R0
	LDR R1, =LED_ON
	STR	R1, [R0]
	
	BX LR ; end sub routine
	ALIGN
		
		



	END ; END of assembly code

; LEGEND:
; EQU 		https://www.keil.com/support/man/docs/armasm/armasm_dom1361290008953.htm
; The EQU directive gives a symbolic name to a numeric constant.

; AREA 	https://www.keil.com/support/man/docs/armasm/armasm_dom1361290002714.htm
; The AREA directive instructs the assembler to assemble a new code or data section.

; THUMB	https://www.keil.com/support/man/docs/armasm/armasm_dom1396000243686.htm

; EXPORT 	https://www.keil.com/support/man/docs/armasm/armasm_dom1361290009343.htm

; Flash memory page 64 RM
; Core registers M4 User Guide pg. 16
; https://azeria-labs.com/memory-instructions-load-and-store-part-4/
; Vector table pg. 37 M4 User guide