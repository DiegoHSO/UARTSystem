library IEEE;
use IEEE.std_logic_1164.all;
use work.p_MR2.all;
use ieee.numeric_std.all;

entity UART is
	port
	(
		TX: out std_logic; -- conexão entre sisA para sisB
		RX: in std_logic; -- conexão entre sisB para sisA
		rw: in std_logic; -- 0 para leitura e 1 para escrita com a UART
		ce: in std_logic; -- 1 indica que a UART foi selecionada e deve responder a um comando
		add: in std_logic_vector(3 downto 0); -- enderecamento (0 a 15)
		data: inout std_logic_vector(7 downto 0); -- sinal de dados que pode tanto receber
																-- do TB quanto enviar para ele
		ck, rst: in std_logic; 
		irTX: out std_logic; -- quando em 1 avisa para o TB que o dado recebido já está iniciando 
									-- sua transmissão através de TX e que este pode enviar um novo dado
									
		ackTX: in std_logic; -- quando em 1 o TB avisa para a UART que leu o sinal irTX							
		irRX: out std_logic;  -- quando em 1 avisa que o dado foi recebido em RX e pode ser lido
		ackRX: in std_logic -- quando em 1 o TB avisa para a UART que leu o sinal irRX
	);
end UART;

architecture UART of UART is
	signal register_w, register_wo, register_ri, register_r: std_logic_vector(7 downto 0);
	type STATE is (idle, start, busy, stop); 
	signal send_state, receive_state: STATE;
	signal transmit, pending: std_logic; 

begin

	read_data: process(rst, ck)
	begin
		if rst = '1' then
			register_w <= (others=>'0');
			register_wo <= (others=>'0');
			irTX <= '0';
			transmit <= '0';
			pending <= '0';
		elsif ck'event and ck = '1' then
			
			if ce = '1' and rw = '0' and add = x"4" then -- 
			-- Pega informação do data e transfere para o registrador de escrita
			-- Torna a flag 'pending' true
					register_w <= data;
					pending <= '1';
			end if;
			
			if pending = '1' then
				-- Caso esteja pendente
				if send_state = idle then -- Caso não esteja enviando data
				-- Transfere o dado do registrador de escrita para o registrador de deslocamento de escrita
					irTX <= '1';	-- Levanta o sinal de send
					register_wo <= register_w;
					transmit <= '1'; -- transmitindo
					pending <= '0'; -- não está mais pendente
				end if;
			end if;
			
			if transmit = '1' and send_state = idle then
				transmit <= '0'; -- Caso esteja transmitindo e esteja no status ocioso
			end if;
			
			if ackTX = '1' then -- Quando o dado é recebido
				irTX <= '0'; -- O sinal de send é abaixado
			end if;	
		end if;
	end process;
	
	write_TX: process(rst, ck)
		-- Transfere o dado entre as UARTs
		variable counter: integer range -2 to 7;
		variable parity: integer := 0;
		
		-- A leitura é feita bit a bit através de deslocamento
	begin
		if rst = '1' then
			TX <= '0';
			send_state <= idle;
		elsif ck'event and ck = '1' then
			case send_state is
				when idle => -- ocioso
						TX <= '0'; -- Não está enviando dados
						if transmit = '1' then -- Caso esteja transmitindo datas
							send_state <= start; -- Inicio do envio de dados
						end if;
				when start => -- inicio do envio de dados de uma UART para OUTRA
						TX <= '1'; -- start bit, protocolo P82
						counter := 7; -- counter: ponteiro para o bit que deve ser enviado, começando pelo último bit
						-- little endian
						send_state <= busy; -- status em 'ocupado'
				when busy => -- Caso esteja realizando o envio de dados, ou seja ocupado
						-- Modificar essa estrutura ---------------------
						if counter >= 0 then -- Caso não 
							TX <= register_wo(counter); -- Tx recebe o bit da posição counter do vetor register_wo 
							if register_wo(counter) = '1' then -- paridade soma se TX = 1
								parity := parity + 1;
							end if;
							counter := counter - 1; -- diminui o contador
						elsif counter = -1 then
							parity := parity mod 2;
							if parity = 1 then
								TX <= '1';
							else 
								TX <= '0';
							end if;
							counter := counter - 1;
						else
							parity := 0 ;
							counter := 0;
							send_state <= stop; --  stado para stop
							TX <= '0'; -- primeiro stop bit
						end if;
						-----------------------------------------------
				when stop =>
					TX <= '0';
					send_state <= idle;
				when others =>
					send_state <= idle;
			end case;
		end if;
	end process;
	
	read_RX: process(rst, ck)
		variable counter: integer range -1 to 7;
	begin
		if rst = '1' then
			register_ri <= (others=>'0');
			register_r <= (others=>'0');
			receive_state <= idle;
		elsif ck'event and ck = '1' then
			case receive_state is
				when idle =>
						if RX = '1' then
							-- Caso esteja em ocioso e o RX seja = 1, quer dizer
							-- que recebou o start bit
							receive_state <= busy;
							-- receive_state recebe estatus 'ocupado'
							counter := 7; -- contador apontar para bit 7
						end if;
				when busy =>
						-- caso esteja ocupado ( recebendo dados )
						-- A escrita em rri é feita bit a bit, através de deslocament
						if counter >= 0 then
							-- contador > 0, registrador de deslocamento de leitura recebe o bit do RX
							register_ri(counter) <= RX;
							counter := counter - 1;
							-- decrementa counter
						else
							-- A leitura de rri é atomica em 8 bits
							register_r <= register_ri;
							receive_state <= stop; -- state recebe stop
						end if;
				when stop =>
					receive_state <= idle; -- caso esteja em stop, troca para ocioso
				when others =>
					--send_state <= idle;
			end case;
		end if;
	end process;
	
	save_data: process(rst, ce, ck)
	begin
		if rst = '1' then
			data <= (others=>'Z');
			irRX <= '0';
		elsif ce = '1' and rw = '1' and add = x"8" then 
				data <= register_r;
				data <= (others=>'Z') after 10ns;
		elsif ck'event and ck = '1' then
			if receive_state = stop then
				irRX <= '1';
			end if;
			if ackRX = '1' then
				irRX <= '0';
			end if;
		end if;
	end process;
end UART;