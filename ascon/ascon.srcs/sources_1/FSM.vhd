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


entity FSM is
    Port ( clk : in STD_LOGIC;
           reset                    : in STD_LOGIC; -- active high
           start                    : in STD_LOGIC; -- active high
           tagsEqual                : in STD_LOGIC;
           input_queue_blocktype    : in blocktype;
           
           input_queue_next         : out STD_LOGIC;
           output_queue_write       : out STD_LOGIC;
           
           valid                    : out STD_LOGIC;
           ready                    : out STD_LOGIC;
           
           operation                : out Opcodes;
           round                    : out STD_LOGIC_VECTOR(3 downto 0)  -- expecting numbers 0 to 11 in binary
           );
end FSM;

architecture Behavioral of FSM is


begin

----------------------------------------------------------------------------------
	-- Please implement your FSM solution here
----------------------------------------------------------------------------------

end Behavioral;
