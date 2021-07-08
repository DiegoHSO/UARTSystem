--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- ALU - operation depends only on the current instruction
--		(decoded in the control unit)
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_arith.all;
use work.p_MR2.all;

entity alu is
	port
	(
		op1, op2: in reg32;
		outalu: out reg32;
		op_alu: in inst_type
	);
end alu;

architecture alu of alu is
	signal menorU, menorS: std_logic;
begin
	menorU <=  '1' when op1 < op2 else '0';
	menorS <=  '1' when IEEE.std_logic_signed."<"(op1, op2) else '0'; -- signed
	outalu <=  op1 - op2
				when  op_alu=SUBU					else
				op1 and op2
				when  op_alu=AAND  or op_alu=ANDI	else
				op1 or  op2
				when  op_alu=OOR	or op_alu=ORI	else
				op1 xor op2
				when  op_alu=XXOR  or op_alu=XORI	else
				to_StdLogicVector(to_bitvector(op1) sll
				CONV_INTEGER(op2(10 downto 6)))
				when  op_alu=SSLL					else
				to_StdLogicVector(to_bitvector(op1) srl
				CONV_INTEGER(op2(10 downto 6)))
				when  op_alu=SSRL					else
				op2(15 downto 0) & x"0000"
				when  op_alu=LUI					else
				(0 => menorU, others => '0')
				when  op_alu=SLTU or op_alu=SLTIU	else	-- signed
				(0 => menorS, others => '0')
				when  op_alu=SLT  or op_alu=SLTI	else	-- unsigned
				-- 22/11/2004 - subtle error correctionwas done for J!
				-- Part of the work for J has been done before, by shifting IR(15 downto 0)
				-- left by two bits before writing data to the IMED register
				op1(31 downto 28) & op2(27 downto 0)
					when  op_alu=J					else
				op1
					when  op_alu=JR	or op_alu=JALR	else
				op1 + op2;
				-- default for ADDU,ADDIU,LBU,LW,SW,SB,BEQ,BGEZ,BLEZ,BNE
end alu;