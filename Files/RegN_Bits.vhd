--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Generic register
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
library IEEE;
use IEEE.std_logic_1164.all;

entity regnbit is
	generic
	(
		N: integer := 16;
		INIT_VALUE: std_logic_vector(31 downto 0) := (others => '0')
	);
	port
	(
		ck, rst, ce: in std_logic;
		D: in std_logic_vector(N-1 downto 0);
		Q: out std_logic_vector(N-1 downto 0)
	);
end regnbit;

architecture regn of regnbit is
begin

	process(ck, rst)
	begin
		if rst = '1' then
			Q <= INIT_VALUE(N-1 downto 0);
		elsif ck'event and ck = '0' then
			if ce = '1' then
				Q <= D;
			end if;
		end if;
	end process;

end regn;