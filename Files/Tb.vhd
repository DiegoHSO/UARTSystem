library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity tb is
end tb;

architecture tb of tb is
	signal AparaB, BparaA: std_logic;
begin
	SA: entity work.sisA port map(TX => AparaB, RX => BparaA);
	SB: entity work.sisB port map(TX => BparaA, RX => AparaB);
end tb;

