-------------------------------------------------------------------------------------------------
-- Company : TUM
-- Author : Zaccarie Kanit
-------------------------------------------------------------------------------------------------
-- Version : V1
-- Version history :
-- V1 : 16-06-2025 : Zaccarie Kanit : Creation
-------------------------------------------------------------------------------------------------
-- File name : adder_tb.vhd
-- Target Devices :
-- File Creation date : 16-06-2025
-- Project name : CD4S project lab 2-3
-------------------------------------------------------------------------------------------------
-- Softwares : Microsoft Windows (Windows 11 Professional) - Editor (Vivado + VSCode)
-------------------------------------------------------------------------------------------------
-- Description: 
-- Comprehensive testbench for the adder component
-- Tests addition, subtraction, carry generation, and edge cases
--
-- Limitations: 
--
-------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-------------------------------------------------------------------------------------------------
-- ENTITY
-------------------------------------------------------------------------------------------------
entity adder_tb is
-- No ports needed for testbench
end adder_tb;

-------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------------------------
architecture Behavioral of adder_tb is

-------------------------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------------------------
constant CLK_PERIOD : time := 10 ns;
constant TEST_WIDTH : integer := 8;  -- Smaller width for easier testing

-------------------------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------------------------
signal clk : std_logic := '0';
signal reset : std_logic := '1';

-- DUT signals
signal a : std_logic_vector(TEST_WIDTH-1 downto 0);
signal b : std_logic_vector(TEST_WIDTH-1 downto 0);
signal neg_b : std_logic;
signal s : std_logic_vector(TEST_WIDTH downto 0);

-- Test control signals
signal test_done : std_logic := '0';
signal test_passed : std_logic := '1';
signal test_count : integer := 0;
signal pass_count : integer := 0;

-------------------------------------------------------------------------------------------------
-- COMPONENT INSTANTIATION
-------------------------------------------------------------------------------------------------
begin

-- Instantiate the adder under test
uut : entity work.adder
generic map(
    input_width => TEST_WIDTH
)
port map(
    a => a,
    b => b,
    neg_b => neg_b,
    s => s
);

-------------------------------------------------------------------------------------------------
-- CLOCK GENERATION
-------------------------------------------------------------------------------------------------
clk <= not clk after CLK_PERIOD/2;

-------------------------------------------------------------------------------------------------
-- TEST PROCESS
-------------------------------------------------------------------------------------------------
test_proc : process
    variable expected_result : std_logic_vector(TEST_WIDTH downto 0);
    variable a_unsigned, b_unsigned : unsigned(TEST_WIDTH-1 downto 0);
    variable result_unsigned : unsigned(TEST_WIDTH downto 0);
begin
    -- Initialize
    a <= (others => '0');
    b <= (others => '0');
    neg_b <= '0';
    reset <= '1';
    wait for CLK_PERIOD;
    reset <= '0';
    wait for CLK_PERIOD;
    
    report "Starting Adder Testbench...";
    report "Testing " & integer'image(TEST_WIDTH) & "-bit adder/subtractor";
    report "==========================================";
    
    -------------------------------------------------------------------------------------------------
    -- TEST 1: Basic Addition Tests
    -------------------------------------------------------------------------------------------------
    report "Test 1: Basic Addition Tests";
    
    -- Test 1.1: Simple addition
    test_count <= test_count + 1;
    a <= "00000001";  -- 1
    b <= "00000010";  -- 2
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "000000011";  -- 3
    if s = expected_result then
        report "Test 1.1 PASSED: 1 + 2 = 3";
        pass_count <= pass_count + 1;
    else
        report "Test 1.1 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 1.2: Addition with carry
    test_count <= test_count + 1;
    a <= "11111111";  -- 255
    b <= "00000001";  -- 1
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "100000000";  -- 256 (carry out)
    if s = expected_result then
        report "Test 1.2 PASSED: 255 + 1 = 256 (with carry)";
        pass_count <= pass_count + 1;
    else
        report "Test 1.2 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 1.3: Zero addition
    test_count <= test_count + 1;
    a <= "00000000";  -- 0
    b <= "00000000";  -- 0
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "000000000";  -- 0
    if s = expected_result then
        report "Test 1.3 PASSED: 0 + 0 = 0";
        pass_count <= pass_count + 1;
    else
        report "Test 1.3 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 2: Basic Subtraction Tests
    -------------------------------------------------------------------------------------------------
    report "Test 2: Basic Subtraction Tests";
    
    -- Test 2.1: Simple subtraction
    test_count <= test_count + 1;
    a <= "00000100";  -- 4
    b <= "00000010";  -- 2
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "000000010";  -- 2
    if s = expected_result then
        report "Test 2.1 PASSED: 4 - 2 = 2";
        pass_count <= pass_count + 1;
    else
        report "Test 2.1 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 2.2: Subtraction with borrow
    test_count <= test_count + 1;
    a <= "00000001";  -- 1
    b <= "00000010";  -- 2
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "111111111";  -- -1 (two's complement)
    if s = expected_result then
        report "Test 2.2 PASSED: 1 - 2 = -1 (with borrow)";
        pass_count <= pass_count + 1;
    else
        report "Test 2.2 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 2.3: Zero subtraction
    test_count <= test_count + 1;
    a <= "00000000";  -- 0
    b <= "00000000";  -- 0
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "000000000";  -- 0
    if s = expected_result then
        report "Test 2.3 PASSED: 0 - 0 = 0";
        pass_count <= pass_count + 1;
    else
        report "Test 2.3 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 3: Edge Cases
    -------------------------------------------------------------------------------------------------
    report "Test 3: Edge Cases";
    
    -- Test 3.1: Maximum value addition
    test_count <= test_count + 1;
    a <= "11111111";  -- 255
    b <= "11111111";  -- 255
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "111111110";  -- 510
    if s = expected_result then
        report "Test 3.1 PASSED: 255 + 255 = 510";
        pass_count <= pass_count + 1;
    else
        report "Test 3.1 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 3.2: Maximum value subtraction
    test_count <= test_count + 1;
    a <= "11111111";  -- 255
    b <= "11111111";  -- 255
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "000000000";  -- 0
    if s = expected_result then
        report "Test 3.2 PASSED: 255 - 255 = 0";
        pass_count <= pass_count + 1;
    else
        report "Test 3.2 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 3.3: All ones pattern
    test_count <= test_count + 1;
    a <= "10101010";  -- 170
    b <= "01010101";  -- 85
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "011111111";  -- 255
    if s = expected_result then
        report "Test 3.3 PASSED: 170 + 85 = 255";
        pass_count <= pass_count + 1;
    else
        report "Test 3.3 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 4: Carry and Overflow Tests
    -------------------------------------------------------------------------------------------------
    report "Test 4: Carry and Overflow Tests";
    
    -- Test 4.1: Carry out test
    test_count <= test_count + 1;
    a <= "10000000";  -- 128
    b <= "10000000";  -- 128
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "100000000";  -- 256 (carry out)
    if s = expected_result then
        report "Test 4.1 PASSED: 128 + 128 = 256 (carry out)";
        pass_count <= pass_count + 1;
    else
        report "Test 4.1 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 4.2: Borrow test
    test_count <= test_count + 1;
    a <= "00000000";  -- 0
    b <= "00000001";  -- 1
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "111111111";  -- -1 (borrow)
    if s = expected_result then
        report "Test 4.2 PASSED: 0 - 1 = -1 (borrow)";
        pass_count <= pass_count + 1;
    else
        report "Test 4.2 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 5: Random Value Tests
    -------------------------------------------------------------------------------------------------
    report "Test 5: Random Value Tests";
    
    -- Test 5.1: Random addition
    test_count <= test_count + 1;
    a <= "11001100";  -- 204
    b <= "00110011";  -- 51
    neg_b <= '0';     -- Addition
    wait for CLK_PERIOD;
    expected_result := "011111111";  -- 255
    if s = expected_result then
        report "Test 5.1 PASSED: 204 + 51 = 255";
        pass_count <= pass_count + 1;
    else
        report "Test 5.1 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -- Test 5.2: Random subtraction
    test_count <= test_count + 1;
    a <= "11110000";  -- 240
    b <= "00001111";  -- 15
    neg_b <= '1';     -- Subtraction
    wait for CLK_PERIOD;
    expected_result := "011110001";  -- 225
    if s = expected_result then
        report "Test 5.2 PASSED: 240 - 15 = 225";
        pass_count <= pass_count + 1;
    else
        report "Test 5.2 FAILED: Expected " & to_string(expected_result) & ", Got " & to_string(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST SUMMARY
    -------------------------------------------------------------------------------------------------
    wait for CLK_PERIOD;
    report "==========================================";
    report "Test Summary:";
    report "Total Tests: " & integer'image(test_count);
    report "Passed: " & integer'image(pass_count);
    report "Failed: " & integer'image(test_count - pass_count);
    
    if test_passed = '1' then
        report "ALL TESTS PASSED! Adder is working correctly.";
    else
        report "SOME TESTS FAILED! Please check the adder implementation.";
    end if;
    
    test_done <= '1';
    wait;
    
end process test_proc;

-------------------------------------------------------------------------------------------------
-- MONITORING PROCESS (Optional)
-------------------------------------------------------------------------------------------------
monitor_proc : process
begin
    wait until test_done = '1';
    wait for CLK_PERIOD;
    report "Testbench completed.";
    wait;
end process monitor_proc;

end Behavioral; 