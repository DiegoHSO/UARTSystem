-------------------------------------------------------------------------
-- Top-level instantiation of the MR2 Datapath and Control Unit
--------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MR2.all;

entity MR2 is
	port
	(
		clock,reset: in std_logic;
		ce: out std_logic_vector(16 downto 0);
		rw, bw: out std_logic;
		i_address, d_address: out reg32;
		instruction: in reg32;
		data: inout reg32;
		irTX, irRX: in std_logic -- Declaracao dos sinais irTX e irRX das UARTs
	);
end MR2;

architecture MR2 of MR2 is
	signal IR: reg32;
	signal uins: microinstruction;
	signal data_address: reg32;
begin
	
	dp: entity work.datapath port map
	(
		ck => clock,
		rst => reset,
		IR_OUT => IR,
		uins => uins,
		i_address => i_address,
		instruction => instruction,
		d_address => data_address,
		data => data,
		irRX => irRX, -- Port map dos sinais das UARTs para o datapath
		irTX => irTX
	);
	ct: entity work.control_unit port map
	(
		ck => clock,
		rst => reset, 
		IR => IR, 
		uins => uins
	);

	rw <= uins.rw;
	bw <= uins.bw;

	----------------------------------------------------------------------------------------------------------
	--- Trecho de codigo inserido para habilitar o CE dos periféricos e memória.
	--- 	O ce(0) e ce(1) e das UARTs
	--- 	O ce(16) e da memória de dados
	--- 	Os demais sao de periféricos de 2 a 15
	--- Alem deste trecho foi inserido a mais na versao gold da MR2:
	---		"APENAS" a codificao da instrucao ERET
	---	Alteracao na entidade com os novos sinais "intr", "inta" e o "ce" de 17 linhas
	----------------------------------------------------------------------------------------------------------
	d_address <= data_address;

	ce(0)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE00000" and data_address<x"FFE10000")) else '0'; -- Ativa a UART
	ce(1)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE10000" and data_address<x"FFE20000")) else '0'; 
	ce(2)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE20000" and data_address<x"FFE30000")) else '0';
	ce(3)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE30000" and data_address<x"FFE40000")) else '0';
	ce(4)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE40000" and data_address<x"FFE50000")) else '0';
	ce(5)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE50000" and data_address<x"FFE60000")) else '0';
	ce(6)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE60000" and data_address<x"FFE70000")) else '0';
	ce(7)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE70000" and data_address<x"FFE80000")) else '0';
	ce(8)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE80000" and data_address<x"FFE90000")) else '0';
	ce(9)  <= '1' when (uins.ceRW='1' and (data_address>=x"FFE90000" and data_address<x"FFEA0000")) else '0';
	ce(10) <= '1' when (uins.ceRW='1' and (data_address>=x"FFEA0000" and data_address<x"FFEB0000")) else '0';
	ce(11) <= '1' when (uins.ceRW='1' and (data_address>=x"FFEB0000" and data_address<x"FFEC0000")) else '0';
	ce(12) <= '1' when (uins.ceRW='1' and (data_address>=x"FFEC0000" and data_address<x"FFED0000")) else '0';
	ce(13) <= '1' when (uins.ceRW='1' and (data_address>=x"FFED0000" and data_address<x"FFEE0000")) else '0';
	ce(14) <= '1' when (uins.ceRW='1' and (data_address>=x"FFEE0000" and data_address<x"FFEF0000")) else '0';
	ce(15) <= '1' when (uins.ceRW='1' and (data_address>=x"FFEF0000" and data_address<x"FFF00000")) else '0';
	ce(16) <= '1' when (uins.ceRW='1' and (data_address<x"FFE00000"  or  data_address>=x"FFF00000")) else '0'; -- Acesso a mem�ria de dados

end MR2;