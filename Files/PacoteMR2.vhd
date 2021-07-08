-------------------------------------------------------------------------
-- package with basic types
-------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

package p_MR2 is

	subtype reg32 is std_logic_vector(31 downto 0);
	subtype reg16 is std_logic_vector(15 downto 0);
	-- inst_type defines the instructions decodeable by the control unit
	type inst_type is
	(
		ADDU, SUBU, AAND, OOR, XXOR, SSLL, SSRL, ADDIU, ANDI, ORI,
		XORI, LUI, LBU, LW, SB, SW, SLT, SLTU, SLTI, SLTIU, BEQ,
		BGEZ, BLEZ, BNE, J, JALR, JR, RFE, ERET, NOP, invalid_instruction
	);

	type microinstruction is record
		CY1: std_logic;	-- command of the first stage
		CY2: std_logic;	--	"	of the second stage
		wula: std_logic;	--	"	of the third stage
		wmdr: std_logic;	--	"	of the fourth stage
		wpc: std_logic;	-- PC write enable
		wreg: std_logic;	-- register bank write enable
		ceRW: std_logic;	-- Chip enable and R_W controls
		rw: std_logic;
		bw: std_logic;	-- Byte-word control (mem write only)
		i: inst_type;	-- operation specification
	end record;

end p_MR2;
