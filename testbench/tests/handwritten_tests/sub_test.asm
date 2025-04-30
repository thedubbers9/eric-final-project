LI R3, 3
LI R1, 2
SUB R1, R3 # SUB Rd, Rs	|||| Rd ← Rs - Rd
LI R9, 14
STOREL R1, R9 # MEM[REG[R3]] <- R1
HALT
