----------------------------------------------------------------------------------
-- Circuit Design for Security Exercise 1
-- ASCON-AEAD 128 NIST SP 800-232 ipd
-- (c) TUM
-- FOR EDUCATIONAL PURPOSE ONLY
----------------------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Common.all;
use IEEE.NUMERIC_STD.ALL;



entity testbench is
--  Port ( );
end testbench;

architecture Behavioral of testbench is

signal clk : STD_LOGIC := '1';
signal reset : STD_LOGIC := '1';
signal start : STD_LOGIC := '0';
           
signal key_reg :  STD_LOGIC_VECTOR (127 downto 0);
                  
signal input_queue_out :  STD_LOGIC_VECTOR (0 to 127);
signal input_queue_blocktype : blocktype;
signal input_queue_next :  STD_LOGIC;
           
signal output_queue_in :  STD_LOGIC_VECTOR (0 to 127);
signal output_queue_write :  STD_LOGIC;

signal valid :  STD_LOGIC;
signal ready :  STD_LOGIC;
        
signal decoding_correct :  STD_LOGIC;
signal next_test :  STD_LOGIC;

constant ClockFrequency : integer := 200e6; -- 100 MHz
constant ClockPeriod    : time    := 1000 ms / ClockFrequency;
       
begin

impl : entity work.ASCON
    port map ( clk => clk, 
        reset => reset, 
        start => start,
        key_reg => key_reg,
        input_queue_out => input_queue_out,
        input_queue_blocktype => input_queue_blocktype,
        input_queue_next => input_queue_next,
        output_queue_in => output_queue_in,
        output_queue_write => output_queue_write,
        valid  => valid,
        ready => ready
     );


  
  Clk <= not Clk after ClockPeriod / 2;
  
  key_reg <= x"3b7fbd091d2ab304ab4013ff9e35452e";

-- this is int64 representation, most software would take little endian
  
    process is
    begin
        input_queue_out <= x"8056e51b628630853ce5f15ba03294ea";
        input_queue_blocktype <= Nonce;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"73736120736920747865742073696854";
        input_queue_blocktype <= AData;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"0100002E61746164206465746169636F";
        input_queue_blocktype <= AData;
        
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"277FDFD82227CF722669ECFFF79C3105";
        input_queue_blocktype <= Message;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"BFAF207789148C0C3A34BA1239D31AA2";
        input_queue_blocktype <= Message;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"565451E0C50DD90363E780AA8BDC7EDC";
        input_queue_blocktype <= Message;        
        
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"035629835A4D42BDC01D8E5CB5DED26A";
        input_queue_blocktype <= Tag;
        wait until ((rising_edge(Clk) and (input_queue_next = '1')) or (rising_edge(next_test)));
        input_queue_out <= (others => 'U');

        wait until falling_edge(next_test);
        input_queue_out <= x"61E741AA7E1A1294DE29CF66329B0AD1";
        input_queue_blocktype <= Nonce;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"BDC4613A39C6EB477FBA2BF85545249A";
        input_queue_blocktype <= Message;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= x"D6A40614CCD09334676A06B676D15F9C";
        input_queue_blocktype <= Tag;
        wait until (rising_edge(Clk) and (input_queue_next = '1'));
        input_queue_out <= (others => 'U');
        wait;
    end process;
    
    process is
    begin
        decoding_correct <= '1';
        wait until (rising_edge(output_queue_write));
        if (output_queue_in = x"2C736E6F6974616C75746172676E6F43") then
            report "First block decrypted correct: " & to_hstring(to_bitvector(output_queue_in)) & "h";
        else
            report "First block missmatch: expected 2C736E6F6974616C75746172676E6F43h, recieved " & to_hstring(to_bitvector(output_queue_in)) & "h";
            decoding_correct <= '0';
        end if;
        wait until (rising_edge(output_queue_write));
        if (output_queue_in = x"742064657470797263656420756F7920") then
            report "Second block decrypted correct: " & to_hstring(to_bitvector(output_queue_in)) & "h";
        else
            report "Second block missmatch: expected 742064657470797263656420756F7920h, recieved " & to_hstring(to_bitvector(output_queue_in)) & "h";
            decoding_correct <= '0';
        end if;
        wait until (rising_edge(output_queue_write));
        if (output_queue_in = x"00002174786574207473657420736968") then
            report "Third block decrypted correct: " & to_hstring(to_bitvector(output_queue_in)) & "h";
        else
            report "Third block missmatch: expected 00002174786574207473657420736968h, recieved " & to_hstring(to_bitvector(output_queue_in)) & "h";
            decoding_correct <= '0';
        end if;
        wait until (rising_edge(ready));
        if (decoding_correct and valid) then
            report "Decrytpion test 1 passed";
        else
            report "Testvector 1 failed";
        end if;
        
        wait until falling_edge(next_test);
        decoding_correct <= '1';
        wait until (rising_edge(output_queue_write));
        if (output_queue_in = x"E99AE9F6FE166BBF3377DE2B8F9319BA") then
            report "First block decrypted correct: " & to_hstring(to_bitvector(output_queue_in)) & "h";
        else
            report "First block missmatch: expected E99AE9F6FE166BBF3377DE2B8F9319BAh, recieved " & to_hstring(to_bitvector(output_queue_in)) & "h";
            decoding_correct <= '0';
        end if;
        wait until (rising_edge(ready));
        if (decoding_correct and valid) then
            report "Decrytpion test 2 passed";
        else
            report "Testvector 2 failed";
        end if;
    end process;
    
    -- Testbench sequence
    process is
    begin
        reset <= '1';
        next_test <= '0';
        wait for 10 ns;
        wait until rising_edge(Clk);
        reset <= '0';
        wait for 10 ns;
        wait until rising_edge(Clk);
        start <= '1';
        wait until rising_edge(Clk);
        start <= '0';
        
        wait until rising_edge(ready);
        wait for 10 ns;
        wait until rising_edge(Clk);
        next_test <= '1';
        wait until rising_edge(Clk);
        next_test <= '0';
        wait until rising_edge(Clk);
        start <= '1';
        wait until rising_edge(Clk);
        start <= '0';
        
        wait;
    end process;
    
end Behavioral;
