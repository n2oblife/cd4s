-------------------------------------------------------------------------------------------------
-- Company : TUM
-- Author : Zaccarie Kanit
-------------------------------------------------------------------------------------------------
-- Version : V1
-- Version history :
-- V1 : 16-06-2025 : Zaccarie Kanit : Creation
-------------------------------------------------------------------------------------------------
-- File name : adder_tb_64bit.vhd
-- Target Devices :
-- File Creation date : 16-06-2025
-- Project name : CD4S project lab 2-3
-------------------------------------------------------------------------------------------------
-- Softwares : Microsoft Windows (Windows 11 Professional) - Editor (Vivado + VSCode)
-------------------------------------------------------------------------------------------------
-- Description: 
-- Advanced testbench for the 64-bit adder component
-- Tests with full 64-bit width and comprehensive edge cases
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
entity adder_tb_64bit is
-- No ports needed for testbench
end adder_tb_64bit;

-------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-------------------------------------------------------------------------------------------------
architecture Behavioral of adder_tb_64bit is

-------------------------------------------------------------------------------------------------
-- CONSTANTS
-------------------------------------------------------------------------------------------------
constant CLK_PERIOD : time := 10 ns;
constant TEST_WIDTH : integer := 64;  -- Full 64-bit testing

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
    
    report "Starting 64-bit Adder Testbench...";
    report "Testing " & integer'image(TEST_WIDTH) & "-bit adder/subtractor";
    report "==========================================";
    
    -------------------------------------------------------------------------------------------------
    -- TEST 1: Basic 64-bit Addition Tests
    -------------------------------------------------------------------------------------------------
    report "Test 1: Basic 64-bit Addition Tests";
    
    -- Test 1.1: Simple 64-bit addition
    test_count <= test_count + 1;
    a <= x"0000000000000001";  -- 1
    b <= x"0000000000000002";  -- 2
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"0000000000000003" & '0';  -- 3
    if s = expected_result then
        report "Test 1.1 PASSED: 1 + 2 = 3";
        pass_count <= pass_count + 1;
    else
        report "Test 1.1 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 1.2: Large number addition
    test_count <= test_count + 1;
    a <= x"7FFFFFFFFFFFFFFF";  -- Max positive 63-bit
    b <= x"0000000000000001";  -- 1
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"8000000000000000" & '0';  -- Max positive + 1
    if s = expected_result then
        report "Test 1.2 PASSED: Max positive + 1";
        pass_count <= pass_count + 1;
    else
        report "Test 1.2 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 1.3: Addition with carry out
    test_count <= test_count + 1;
    a <= x"FFFFFFFFFFFFFFFF";  -- Max 64-bit
    b <= x"0000000000000001";  -- 1
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"0000000000000000" & '1';  -- 0 with carry out
    if s = expected_result then
        report "Test 1.3 PASSED: Max + 1 = 0 (with carry)";
        pass_count <= pass_count + 1;
    else
        report "Test 1.3 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 2: Basic 64-bit Subtraction Tests
    -------------------------------------------------------------------------------------------------
    report "Test 2: Basic 64-bit Subtraction Tests";
    
    -- Test 2.1: Simple 64-bit subtraction
    test_count <= test_count + 1;
    a <= x"0000000000000004";  -- 4
    b <= x"0000000000000002";  -- 2
    neg_b <= '1';              -- Subtraction
    wait for CLK_PERIOD;
    expected_result := x"0000000000000002" & '0';  -- 2
    if s = expected_result then
        report "Test 2.1 PASSED: 4 - 2 = 2";
        pass_count <= pass_count + 1;
    else
        report "Test 2.1 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 2.2: Subtraction with borrow
    test_count <= test_count + 1;
    a <= x"0000000000000001";  -- 1
    b <= x"0000000000000002";  -- 2
    neg_b <= '1';              -- Subtraction
    wait for CLK_PERIOD;
    expected_result := x"FFFFFFFFFFFFFFFF" & '1';  -- -1 (two's complement with borrow)
    if s = expected_result then
        report "Test 2.2 PASSED: 1 - 2 = -1 (with borrow)";
        pass_count <= pass_count + 1;
    else
        report "Test 2.2 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 2.3: Large number subtraction
    test_count <= test_count + 1;
    a <= x"8000000000000000";  -- Large number
    b <= x"0000000000000001";  -- 1
    neg_b <= '1';              -- Subtraction
    wait for CLK_PERIOD;
    expected_result := x"7FFFFFFFFFFFFFFF" & '0';  -- Large number - 1
    if s = expected_result then
        report "Test 2.3 PASSED: Large - 1";
        pass_count <= pass_count + 1;
    else
        report "Test 2.3 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 3: Edge Cases and Boundary Conditions
    -------------------------------------------------------------------------------------------------
    report "Test 3: Edge Cases and Boundary Conditions";
    
    -- Test 3.1: Zero operations
    test_count <= test_count + 1;
    a <= x"0000000000000000";  -- 0
    b <= x"0000000000000000";  -- 0
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"0000000000000000" & '0';  -- 0
    if s = expected_result then
        report "Test 3.1 PASSED: 0 + 0 = 0";
        pass_count <= pass_count + 1;
    else
        report "Test 3.1 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 3.2: Maximum value operations
    test_count <= test_count + 1;
    a <= x"FFFFFFFFFFFFFFFF";  -- Max 64-bit
    b <= x"FFFFFFFFFFFFFFFF";  -- Max 64-bit
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"FFFFFFFFFFFFFFFE" & '1';  -- Max + Max = 2*Max (with carry)
    if s = expected_result then
        report "Test 3.2 PASSED: Max + Max = 2*Max (with carry)";
        pass_count <= pass_count + 1;
    else
        report "Test 3.2 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 3.3: Pattern-based tests
    test_count <= test_count + 1;
    a <= x"AAAAAAAAAAAAAAAA";  -- Alternating pattern
    b <= x"5555555555555555";  -- Opposite alternating pattern
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"FFFFFFFFFFFFFFFF" & '0';  -- All ones
    if s = expected_result then
        report "Test 3.3 PASSED: Alternating patterns sum to all ones";
        pass_count <= pass_count + 1;
    else
        report "Test 3.3 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 4: Cryptographic-Style Tests (Large Numbers)
    -------------------------------------------------------------------------------------------------
    report "Test 4: Cryptographic-Style Tests";
    
    -- Test 4.1: Large prime-like numbers
    test_count <= test_count + 1;
    a <= x"FFFFFFFFFFFFFFF5";  -- Large number (close to max)
    b <= x"000000000000000B";  -- 11
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"0000000000000000" & '1';  -- Should wrap around with carry
    if s = expected_result then
        report "Test 4.1 PASSED: Large + 11 = 0 (with carry)";
        pass_count <= pass_count + 1;
    else
        report "Test 4.1 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -- Test 4.2: Modular arithmetic simulation
    test_count <= test_count + 1;
    a <= x"0000000000000003";  -- 3
    b <= x"FFFFFFFFFFFFFFFD";  -- -3 (two's complement)
    neg_b <= '0';              -- Addition
    wait for CLK_PERIOD;
    expected_result := x"0000000000000000" & '1';  -- 0 with carry
    if s = expected_result then
        report "Test 4.2 PASSED: 3 + (-3) = 0 (with carry)";
        pass_count <= pass_count + 1;
    else
        report "Test 4.2 FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
        test_passed <= '0';
    end if;
    
    -------------------------------------------------------------------------------------------------
    -- TEST 5: Stress Tests
    -------------------------------------------------------------------------------------------------
    report "Test 5: Stress Tests";
    
    -- Test 5.1: Multiple rapid operations
    for i in 1 to 10 loop
        test_count <= test_count + 1;
        a <= std_logic_vector(to_unsigned(i, TEST_WIDTH));
        b <= std_logic_vector(to_unsigned(i*2, TEST_WIDTH));
        neg_b <= '0';  -- Addition
        wait for CLK_PERIOD;
        expected_result := std_logic_vector(to_unsigned(i + i*2, TEST_WIDTH + 1));
        if s = expected_result then
            report "Test 5.1." & integer'image(i) & " PASSED: " & integer'image(i) & " + " & integer'image(i*2) & " = " & integer'image(i + i*2);
            pass_count <= pass_count + 1;
        else
            report "Test 5.1." & integer'image(i) & " FAILED: Expected " & to_hstring(expected_result) & ", Got " & to_hstring(s);
            test_passed <= '0';
        end if;
    end loop;
    
    -------------------------------------------------------------------------------------------------
    -- TEST SUMMARY
    -------------------------------------------------------------------------------------------------
    wait for CLK_PERIOD;
    report "==========================================";
    report "64-bit Test Summary:";
    report "Total Tests: " & integer'image(test_count);
    report "Passed: " & integer'image(pass_count);
    report "Failed: " & integer'image(test_count - pass_count);
    
    if test_passed = '1' then
        report "ALL 64-BIT TESTS PASSED! Adder is working correctly.";
    else
        report "SOME 64-BIT TESTS FAILED! Please check the adder implementation.";
    end if;
    
    test_done <= '1';
    wait;
    
end process test_proc;

-------------------------------------------------------------------------------------------------
-- MONITORING PROCESS
-------------------------------------------------------------------------------------------------
monitor_proc : process
begin
    wait until test_done = '1';
    wait for CLK_PERIOD;
    report "64-bit testbench completed.";
    wait;
end process monitor_proc;

end Behavioral; 