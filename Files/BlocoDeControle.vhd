-------------------------------------------------------------------------
--  Control Unit behavioral description
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MR2.all;

entity control_unit is
	port
	(
		ck, rst: in std_logic;
		uins: out microinstruction;
		ir: in reg32
	);
end control_unit;

architecture control_unit of control_unit is
	type type_state is (Sidle, Sfetch, Sreg, Salu, Wbk, Sld, Sst, Salta);
	signal EA, PE: type_state;
	signal i: inst_type;
begin
	----------------------------------------------------------------------------------------
	-- BLOCK (1/3) - INSTRUCTION DECODING and ALU operation definition.
	-- This block generates 1 Output Function of the Control Unit
	----------------------------------------------------------------------------------------
	i <=	ADDU  when ir(31 downto 26)="000000" and ir(5 downto 0)="100001" else
			SUBU  when ir(31 downto 26)="000000" and ir(5 downto 0)="100011" else
			AAND  when ir(31 downto 26)="000000" and ir(5 downto 0)="100100" else
			OOR   when ir(31 downto 26)="000000" and ir(5 downto 0)="100101" else
			XXOR  when ir(31 downto 26)="000000" and ir(5 downto 0)="100110" else
			SSLL  when ir(31 downto 21)="00000000000" and ir(5 downto 0)="000000" and IR(25 downto 9) /= "00000000000000000" else
			SSRL  when ir(31 downto 21)="00000000000" and ir(5 downto 0)="000010" else
			ADDIU when ir(31 downto 26)="001001" else
			ANDI  when ir(31 downto 26)="001100" else
			ORI   when ir(31 downto 26)="001101" else
			XORI  when ir(31 downto 26)="001110" else
			LUI   when ir(31 downto 26)="001111" else
			LW    when ir(31 downto 26)="100011" else
			LBU   when ir(31 downto 26)="100100" else
			SW    when ir(31 downto 26)="101011" else
			SB    when ir(31 downto 26)="101000" else
			SLTU  when ir(31 downto 26)="000000" and ir(5 downto 0)="101011" else
			SLT   when ir(31 downto 26)="000000" and ir(5 downto 0)="101010" else
			SLTIU when ir(31 downto 26)="001011" else
			SLTI  when ir(31 downto 26)="001010" else
			BEQ   when ir(31 downto 26)="000100" else
			BGEZ  when ir(31 downto 26)="000001" else
			BLEZ  when ir(31 downto 26)="000110" else
			BNE   when ir(31 downto 26)="000101" else
			J     when ir(31 downto 26)="000010" else
			JALR  when ir(31 downto 26)="000000"  and ir(20 downto 16)="00000" and ir(10 downto 0) = "00000001001" else
			JR    when ir(31 downto 26)="000000" and ir(5 downto 0)="001000" else
			RFE   when ir=x"42000010" else
			ERET  when ir=x"42000018" else
			NOP	when IR(31 downto 0)=x"00000000" else
			invalid_instruction; -- IMPORTANT: default condition is invalid instruction;

	assert i /= invalid_instruction
		report "******************* INVALID INSTRUCTION *************"
		severity error;

	uins.i <= i;	-- this instructs the alu to execute its expected operation, if any

	----------------------------------------------------------------------------------------
	-- BLOCK (3/3) - DATAPATH REGISTERS load control signals generation.
	----------------------------------------------------------------------------------------
	uins.CY1  <= '1' when EA=Sfetch else '0';
	uins.CY2  <= '1' when EA=Sreg else '0';
	uins.wula <= '1' when EA=Salu else '0';
	uins.wmdr <= '1' when EA=Sld  else '0';
	uins.wreg <= '1' when EA=Wbk or (EA=salta and i=JALR) else '0';
	uins.rw   <= '0' when EA=Sst else '1';
	uins.ceRW <= '1' when EA=Sld or EA=Sst else '0';
	uins.bw   <= '0' when (EA=Sst and i=SB) else '1';
	uins.wpc  <= '1' when (EA=Wbk or EA=Sst or EA=Salta) else '0';

	---------------------------------------------------------------------------------------------
	-- BLOCK (2/3) - Sequential part of the control unit - two processes implementing the
	-- Control Unit state register and the next-state (combinational) function
	---------------------------------------------------------------------------------------------
	process(rst, ck)
	begin
		if rst='1' then
			EA <= Sidle;
	-- Sidle is the state the machine stays while processor is being reset
		elsif ck'event and ck='1' then
			if EA=Sidle then
				EA <= Sfetch;
			else
				EA <= PE;
			end if;
		end if;
	end process;

	process(EA, i)
		-- NEXT state: depends on the PRESENT state and on the current instruction
	begin
		case EA is
			when Sidle => PE <= Sidle; -- reset being active, the processor do nothing!
			-- first stage:  read the current instruction
			when Sfetch => PE <= Sreg;
			-- second stage: read the register banck and store the mask (when i=stmsk)
			when Sreg => PE <= Salu;
			-- third stage: alu operation
			when Salu  => if i=LW  or i=LBU then
								PE <= Sld;
						elsif i=SW or i=SB then
								PE <= Sst;
						elsif i=J or i=JALR or i=JR or i=BEQ or i=BGEZ or i=BLEZ  or i=BNE then
								PE <= Salta;
						else
								PE <= Wbk;
						end if;
			-- fourth stage: data memory operation
			when Sld  => 	PE <= Wbk;
			-- fifth clock cycle of most instructions  - GO BACK TO FETCH
			when Sst | Salta | Wbk => PE <= Sfetch;
		end case;
	end process;

end control_unit;