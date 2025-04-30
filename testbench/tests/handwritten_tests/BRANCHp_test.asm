LI R0, 0
LI R5, 6
SL R0, R5 ## zero out R0.
LI R3, 14 # 000000000011
NOT R3, R3
LI R9, 14
STOREL R3, R9 # STOREL Rd, Rs    MEM[REG[Rs]] <- Rd
STOREU R3, R9 # STOREU Rd, Rs    MEM[REG[Rs]] <- Rd
LOAD R6, R9
AND R2, R0 # zero out R1
LI R2, -5 # Initialize loop counter
AND R1, R0 # zero out R1
LI R1, 1 # Initialize increment amount 
LI R9, -3 ## Jump amount
BRANCHp 9 #<halt, +9>
ADD R2, R1
JUMP R9 # <branchz>
LI R14, 0
LI R7, 5
LI R2, 2
SL R7, R2 # R7 <- 20
NOP
STOREL R6, R7 # STOREL Rd, Rs    MEM[REG[Rs]] <- Rd
STOREU R6, R7 # STOREU Rd, Rs    MEM[REG[Rs]] <- Rd
HALT
