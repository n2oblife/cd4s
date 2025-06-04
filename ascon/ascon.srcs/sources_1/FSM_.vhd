-- FSM claude

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
use ieee.math_real.all;

entity FSM is
    generic (
        g_a         : integer := 12;
        g_b         : integer := 8;
        g_rnd_width : integer := positive(ceil(log2(real(maximum(g_a, g_b)) + real(1))))
    );
    Port ( 
        clk                      : in STD_LOGIC;
        reset                    : in STD_LOGIC;
        start                    : in STD_LOGIC;
        tagsEqual                : in STD_LOGIC;
        input_queue_blocktype    : in blocktype;
        
        input_queue_next         : out STD_LOGIC;
        output_queue_write       : out STD_LOGIC;
        
        valid                    : out STD_LOGIC;
        ready                    : out STD_LOGIC;
        
        operation                : out Opcodes;
        round                    : out STD_LOGIC_VECTOR(g_rnd_width-1 downto 0)
    );
end FSM;

architecture Behavioral of FSM is
    
    -- FSM States
    type state_type is (
        IDLE,           -- Waiting for start
        INIT_ROUND,     -- Initialization permutation rounds
        INIT_KEY,       -- XOR with key after initialization
        AD_PROCESS,     -- Processing associated data
        AD_ONE,         -- Domain separation after AD
        MSG_PROCESS,    -- Processing message/ciphertext
        FINAL_KEY,      -- XOR with key before finalization
        FINAL_ROUND,    -- Finalization permutation rounds
        TAG_OUTPUT,     -- Output/verify tag
        DONE            -- Operation complete
    );
    
    signal current_state, next_state : state_type;
    signal round_counter : integer range 0 to g_a;
    signal round_counter_next : integer range 0 to g_a;
    
begin

    -- State register process
    state_reg: process(clk, reset)
    begin
        if reset = '1' then
            current_state <= IDLE;
            round_counter <= 0;
        elsif rising_edge(clk) then
            current_state <= next_state;
            round_counter <= round_counter_next;
        end if;
    end process;
    
    -- Next state logic and output logic
    fsm_logic: process(current_state, start, input_queue_blocktype, tagsEqual, round_counter)
    begin
        -- Default assignments
        next_state <= current_state;
        round_counter_next <= round_counter;
        input_queue_next <= '0';
        output_queue_write <= '0';
        valid <= '0';
        ready <= '0';
        operation <= NOP;
        round <= std_logic_vector(to_unsigned(round_counter, g_rnd_width));
        
        case current_state is
            
            when IDLE =>
                ready <= '1';
                if start = '1' then
                    next_state <= INIT_ROUND;
                    round_counter_next <= 0;
                    operation <= Init;
                end if;
            
            when INIT_ROUND =>
                operation <= applyRound;
                if round_counter < g_a - 1 then
                    round_counter_next <= round_counter + 1;
                else
                    next_state <= INIT_KEY;
                    round_counter_next <= 0;
                end if;
            
            when INIT_KEY =>
                operation <= applyKeyI;
                next_state <= AD_PROCESS;
                input_queue_next <= '1';  -- Request first AD block
            
            when AD_PROCESS =>
                case input_queue_blocktype is
                    when AData =>
                        operation <= applyAD;
                        if round_counter < g_b - 1 then
                            round_counter_next <= round_counter + 1;
                        else
                            round_counter_next <= 0;
                            input_queue_next <= '1';  -- Request next block
                        end if;
                    
                    when Message =>
                        -- No more AD blocks, add domain separation
                        next_state <= AD_ONE;
                        round_counter_next <= 0;
                    
                    when others =>
                        -- Unexpected block type
                        next_state <= IDLE;
                end case;
            
            when AD_ONE =>
                operation <= applyOne;
                next_state <= MSG_PROCESS;
                input_queue_next <= '1';  -- Request first message block
            
            when MSG_PROCESS =>
                case input_queue_blocktype is
                    when Message =>
                        operation <= applyDec;  -- Works for both enc/dec
                        output_queue_write <= '1';  -- Output processed block
                        
                        if round_counter < g_b - 1 then
                            round_counter_next <= round_counter + 1;
                        else
                            round_counter_next <= 0;
                            input_queue_next <= '1';  -- Request next block
                        end if;
                    
                    when Tag =>
                        -- No more message blocks, proceed to finalization
                        next_state <= FINAL_KEY;
                        round_counter_next <= 0;
                    
                    when others =>
                        -- Unexpected block type
                        next_state <= IDLE;
                end case;
            
            when FINAL_KEY =>
                operation <= applyKeyF;
                next_state <= FINAL_ROUND;
                round_counter_next <= 0;
            
            when FINAL_ROUND =>
                operation <= applyRound;
                if round_counter < g_a - 1 then
                    round_counter_next <= round_counter + 1;
                else
                    next_state <= TAG_OUTPUT;
                    round_counter_next <= 0;
                end if;
            
            when TAG_OUTPUT =>
                case input_queue_blocktype is
                    when Tag =>
                        -- For decryption: verify tag
                        if tagsEqual = '1' then
                            valid <= '1';
                        else
                            valid <= '0';
                        end if;
                        next_state <= DONE;
                    
                    when others =>
                        -- For encryption: output tag
                        output_queue_write <= '1';
                        valid <= '1';
                        next_state <= DONE;
                end case;
            
            when DONE =>
                valid <= '1';
                if start = '0' then
                    next_state <= IDLE;
                end if;
            
            when others =>
                next_state <= IDLE;
                
        end case;
    end process;

end Behavioral;