library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


-------------------------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------------------------
entity field_inverse_eea is
Generic (
    input_width : integer := 64
);
Port (
    clk	    : in STD_LOGIC;
    reset   : in STD_LOGIC;
    input_r	: in std_logic;                                 -- computation starts at '1'
    u       : in STD_LOGIC_VECTOR(input_width-1 downto 0);  -- positive
    v       : in STD_LOGIC_VECTOR(input_width-1 downto 0);  -- positive
    
    done    : out STD_LOGIC;
    inverse : out STD_LOGIC_VECTOR(input_width-1 downto 0)  -- should be positive and under p
);
end field_inverse_eea;


-------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------------------------
architecture Behavioral of field_inverse_eea is

-------------------------------------------------------------------------------------------------
-- COMPONENTS
-------------------------------------------------------------------------------------------------

-- IP_ADDER
component adder is
    Generic (
        input_width : integer := 64
    );
    Port (
        a       : in STD_LOGIC_VECTOR(input_width-1 downto 0);
        b       : in STD_LOGIC_VECTOR(input_width-1 downto 0);
        neg_b   : in STD_LOGIC; -- '0' for addition, '1' for subtraction
        
        s       : out STD_LOGIC_VECTOR(input_width downto 0)  -- Result with carry bit
    );
end component adder;

begin

-------------------------------------------------------------------------------------------------
-- MAPPING
-------------------------------------------------------------------------------------------------

-- IP_ADDER
-- IP_adder : adder
-- generic map(
--     input_width => input_width,
-- );
-- port map(
--     a     => ,
--     b     => ,
--     neg_b => ,      
--     s     =>
-- );

-------------------------------------------------------------------------------------------------
-- PROCESS
-------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------
	-- Please implement your logic and FSM solution here
	-- Instantiate the adder(s) instead of using STD NUMERIC
----------------------------------------------------------------------------------

end Behavioral;
