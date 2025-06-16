-------------------------------------------------------------------------------------------------
-- Company : TUM
-- Author : Zaccarie Kanit
-------------------------------------------------------------------------------------------------
-- Version : V1
-- Version history :
-- V1 : 16-06-2025 : Zaccarie Kanit : Creation
-------------------------------------------------------------------------------------------------
-- File name : adder.vhd
-- Target Devices :
-- File Creation date : 16-06-2025
-- Project name : CD4S project lab 2-3
-------------------------------------------------------------------------------------------------
-- Softwares : Microsoft Windows (Windows 11 Professional) - Editor (Vivado + VSCode)
-------------------------------------------------------------------------------------------------
-- Description: 
--
-- Limitations: 
--
-------------------------------------------------------------------------------------------------
-- Naming conventions:
--
-- i_Port: Input entity port
-- o_Port: Output entity port
-- b_Port: Bidirectional entity port
-- g_My_Generic: Generic entity port
--
-- c_My_Constant: Constant definition
-- t_My_Type: Custom type definition
--
-- sc_My_Signal : Signal between components
-- My_Signal_n: Active low signal
-- v_My_Variable: Variable
-- sm_My_Signal: FSM signal
-- pkg_Param: Element Param coming from a package
--
-- My_Signal_re: Rising edge detection of My_Signal
-- My_Signal_fe: Falling edge detection of My_Signal
-- My_Signal_rX: X times registered My_Signal signal
--
-- P_Process_Name: Process
-- p_procedure_Name : procedure
--
-------------------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-------------------------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------------------------
entity adder is
Generic (
    input_width : integer := 64
);
Port (
    a       : in STD_LOGIC_VECTOR(input_width-1 downto 0);
    b       : in STD_LOGIC_VECTOR(input_width-1 downto 0);
    neg_b   : in STD_LOGIC; -- '0' for addition, '1' for subtraction
    
    s       : out STD_LOGIC_VECTOR(input_width downto 0)  -- Result with carry bit
);
attribute dont_touch : string;
attribute dont_touch of adder : entity is "true";
end adder;

-------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------------------------
architecture Behavioral of adder is

-------------------------------------------------------------------------------------------------
-- PROCESS
-------------------------------------------------------------------------------------------------

    -- 1-bit Partial Full Adder procedure
    procedure p_partial_full_adder (
        variable i_A : in  std_logic;
        variable i_B : in  std_logic;
        variable i_C : in  std_logic;
        variable o_S : out std_logic;
        variable o_C : out std_logic
    ) is
    begin
        o_S := (i_A xor i_B) xor i_C;
        o_C := (i_A and i_B) or ((i_A or i_B) and i_C);
    end procedure p_partial_full_adder;

    -- Two's complement procedure (for subtraction)
    procedure p_twos_complement (
        variable i_A : in  std_logic_vector;
        variable o_A : out std_logic_vector
    ) is
        variable temp_carry : std_logic;
        variable temp_sum   : std_logic;
    begin
        -- First invert all bits
        for i in i_A'range loop
            o_A(i) := not i_A(i);
        end loop;
        
        -- Then add 1 (simple ripple add for the +1)
        temp_carry := '1';
        for i in 0 to i_A'high loop
            temp_sum := o_A(i) xor temp_carry;
            temp_carry := o_A(i) and temp_carry;
            o_A(i) := temp_sum;
        end loop;
    end procedure p_twos_complement;

    -- Generic Carry Lookahead Adder procedure
    procedure p_CLA (
        variable i_A         : in  std_logic_vector;
        variable i_B         : in  std_logic_vector;
        variable i_C         : in  std_logic;
        variable o_S         : out std_logic_vector;
        variable o_C         : out std_logic;
        constant dataWidth   : in  integer
    ) is
        variable s_C : std_logic_vector(0 to dataWidth);
    begin
        s_C(0) := i_C;
        
        -- Generate sum and carry for each bit
        for i in 0 to dataWidth-1 loop
            p_partial_full_adder(i_A(i), i_B(i), s_C(i), o_S(i), s_C(i+1));
        end loop;
        
        o_C := s_C(dataWidth);
    end procedure p_CLA;

begin

    process(a, b, neg_b)
        variable v_A, v_B, v_result : std_logic_vector(input_width-1 downto 0);
        variable v_B_complement     : std_logic_vector(input_width-1 downto 0);
        variable v_carry_in         : std_logic;
        variable v_carry_out        : std_logic;
    begin
        v_A := a;
        v_B := b;
        
        if neg_b = '1' then
            -- Subtraction: A - B = A + (-B) = A + two's complement of B
            p_twos_complement(v_B, v_B_complement);
            v_carry_in := '0';
            p_CLA(v_A, v_B_complement, v_carry_in, v_result, v_carry_out, input_width);
        else
            -- Addition: A + B
            v_carry_in := '0';
            p_CLA(v_A, v_B, v_carry_in, v_result, v_carry_out, input_width);
        end if;
        
        -- Assign result with carry bit
        s <= v_carry_out & v_result;
        
    end process;
-------------------------------------------------------------------------------------------------
end Behavioral;
-------------------------------------------------------------------------------------------------