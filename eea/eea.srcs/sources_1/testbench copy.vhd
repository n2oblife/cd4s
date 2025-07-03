library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity field_inverse_eea_tb is
-- PORT ();
end field_inverse_eea_tb;

architecture Behavioral of field_inverse_eea_tb is

CONSTANT period : TIME := 50 ns;
signal u,v : std_logic_vector (63 downto 0);
signal inverse : std_logic_vector (63 downto 0);
SIGNAL CLK : STD_LOGIC := '0';
signal RST,DONE,input_r : std_logic;
 
begin
uut: entity work.field_inverse_eea(Behavioral)
Generic map(
	input_width => 64
)
PORT MAP (
    u => u,
 	v => v,
    input_r => input_r,
    inverse	=> inverse,
 	clk	=> CLK,
  	reset => RST,
    done => DONE
);

generate_clock : process (clk)
begin
	CLK <= NOT CLK AFTER period/2; -- this necessitates init value
end process;
     
tb : process
begin

	RST<='1';
	u<=x"0000000000000009";
	v<=x"000000000000000D";
	
	wait for period;
	
	RST<='0';

	wait for period;

	input_r <= '1';

	wait for 2*period;

	input_r <= '0';
	
	wait until done = '1';
	
	wait until rising_edge(clk) and done = '1';
	
	if inverse = x"0000000000000003" then
		report "Inverse 1 correct.";
	else
		report "Inverse 1 wrong.";
	end if;

	input_r <= '0';	
	RST<='1';
	
	u<=x"000000000000000D";
	v<=x"0003FFFFFFFFFFE5";
	
	wait for period;

	RST<='0';

	wait for period;

	input_r <= '1';
	
	wait for 2*period;

	input_r <= '0';
	
	wait until DONE = '1';
	
	wait until rising_edge(clk) and done = '1';

	if inverse = x"00013B13B13B13A9" then
		report "Inverse 2 correct.";
	else
		report "Inverse 2 wrong.";
	end if;

end process;

end Behavioral;