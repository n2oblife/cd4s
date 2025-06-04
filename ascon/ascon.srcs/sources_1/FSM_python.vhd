-- FSM based on python

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
    -- number of rounds
    generic (
        g_a         : integer := 12;
        g_b         : integer := 8;
        g_rnd_width : integer := positive(ceil(log2(real(maximum(g_a, g_b)) + real(1))))
        );
    Port ( 
        clk                      : in STD_LOGIC;
        reset                    : in STD_LOGIC; -- active high
        start                    : in STD_LOGIC; -- active high
        tagsEqual                : in STD_LOGIC;
        input_queue_blocktype    : in blocktype;
        
        input_queue_next         : out STD_LOGIC;
        output_queue_write       : out STD_LOGIC;
        
        valid                    : out STD_LOGIC;
        ready                    : out STD_LOGIC;
        
        operation                : out Opcodes;
        round                    : out STD_LOGIC_VECTOR(g_rnd_width-1 downto 0)  -- expecting numbers 0 to 11 in binary
        );
end FSM;

architecture Behavioral of FSM is

-------------------------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------------------------

type t_state is (IDLE, WAIT_FIRST, INIT_DO, INIT_PROCESS_A, INIT_KEY, AD_DO, AD_PROCESS_B, WAIT_MESSAGE, AD_FINISH, DEC_DO, DEC_PROCESS_B, WAIT_CIPHER, WAIT_CIPHER_DELAY, WAIT_LAST, FIN_DO, FIN_PROCESS_A, FIN_DO_LAST, FIN_RESULT);
signal s_state : t_state;

signal s_ctr                    : integer;      -- Round counters 
signal s_init_done, s_ad_done, s_decrypting     : std_logic;    -- serves as output for the first two wait states

begin

-------------------------------------------------------------------------------------------------
-- PROCESS
-------------------------------------------------------------------------------------------------

    -- State_machine_ctrl
    -- Process Description : Handling the state during the decryption phase
    -- Process is synchronous to FPGA's clock
    -- Additional details : divised into 2 processes to avoid combinational loops

    -- Next state process
    P_next_state : process (clk)
    begin
        -- processing pipeline for BP detection
        if rising_edge(clk) then
            case s_state is
                when IDLE => if start then s_state <= WAIT_FIRST; end if;
                
                when WAIT_FIRST =>
                case input_queue_blocktype is
                    when Nonce      => s_state <= INIT_DO;
                    when AData      => s_state <= AD_DO;
                    when Message    => if s_ad_done then    s_state <= AD_FINISH; 
                                        else                s_state <= DEC_DO; 
                                        end if;
                    when others     => s_state <= IDLE;
                end case;
                
                when INIT_DO        => s_state <= INIT_PROCESS_A;
                when INIT_PROCESS_A => if (s_ctr = g_a-1) then s_state <= INIT_KEY; end if;     
                when INIT_KEY       => s_state <= WAIT_FIRST;
                when AD_DO          => s_state <= AD_PROCESS_B;
                when AD_PROCESS_B   => if (s_ctr = g_b-1) then s_state <= WAIT_MESSAGE; end if;
                when WAIT_MESSAGE   => s_state <= WAIT_FIRST;
                when AD_FINISH      => s_state <= DEC_DO;
                --when DEC_DO         => if s_decrypting then s_state <= WAIT_LAST; else s_state <= DEC_PROCESS_B; end if;
                when DEC_DO         => s_state <= WAIT_LAST;
                when DEC_PROCESS_B  => if (s_ctr = g_b - 1) then s_state <= WAIT_CIPHER; end if;
                when WAIT_CIPHER    => s_state <= WAIT_CIPHER_DELAY; -- let's some delay to check result

                when WAIT_CIPHER_DELAY =>
                case input_queue_blocktype is
                    when Message    => s_state <= DEC_DO;
                    when Tag        => s_state <= FIN_DO;
                    when others     => s_state <= IDLE;
                end case;

                when WAIT_LAST =>
                case input_queue_blocktype is
                    when Message    => s_state <= DEC_PROCESS_B;
                    when Tag        => s_state <= FIN_DO;
                    when others     => s_state <= IDLE;
                end case;

                when FIN_DO         => s_state <= FIN_PROCESS_A;
                when FIN_PROCESS_A  => if (s_ctr = g_a-1) then s_state <= FIN_DO_LAST; end if;
                when FIN_DO_LAST    => s_state <= FIN_RESULT;
                when FIN_RESULT     => s_state <= IDLE;
                when others         => s_state <= IDLE;

            end case;

            -- in case CPU stops IP or reset
            if reset then
                s_state <= IDLE;
            end if;

        end if;
    end process P_next_state;

    -- Output logic
    P_output_logic : process (clk)
    begin
    if rising_edge(clk) then
        case s_state is
            when IDLE =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when WAIT_FIRST =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when INIT_DO =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= Init;
                round               <= (others => '0');
            when INIT_PROCESS_A =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= std_logic_vector(to_unsigned(s_ctr, g_rnd_width));
            when INIT_KEY =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyKeyI;
                round               <= (others => '0');
            when AD_DO =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyAD;
                round               <= (others => '0');
            when AD_PROCESS_B =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= std_logic_vector(to_unsigned(s_ctr, g_rnd_width));
            when WAIT_MESSAGE =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when AD_FINISH =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyOne;
                round               <= (others => '0');
            when DEC_DO =>
                input_queue_next    <= '1';
                output_queue_write  <= '1';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyDec;
                round               <= (others => '0');
            when DEC_PROCESS_B =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= std_logic_vector(to_unsigned(s_ctr, g_rnd_width));
            when WAIT_CIPHER =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when WAIT_LAST =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when FIN_DO =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyKeyF;
                round               <= (others => '0');
            when FIN_PROCESS_A =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= std_logic_vector(to_unsigned(s_ctr, g_rnd_width));
            when FIN_DO_LAST =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyKeyF;
                round               <= (others => '0');
            when FIN_RESULT =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= tagsEqual;
                ready               <= '1';
                operation           <= NOP;
                round               <= (others => '0');
            when others =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');        
        end case;
    end if;
    end process P_output_logic;
    
    -- Internal Signal logic
    P_int_sig_logic : process (clk)
    begin
    if rising_edge(clk) then
        case s_state is
                when IDLE =>
                s_init_done <= '0';
                s_ctr       <= 0;
                s_ad_done   <= '0';
                s_decrypting <= '0';
                
                when INIT_PROCESS_A =>
                s_ctr <= s_ctr + 1;
                if s_ctr = g_a-1 then
                    s_ctr <= g_a - g_b; -- don't know why but should do the permutation from 4to 11
                end if;  
                
                when INIT_KEY => s_init_done <= '1';
                
                when AD_DO => s_ad_done <= '1';
                
                when AD_PROCESS_B =>
                s_ctr <= s_ctr + 1;
                if s_ctr = g_b-1 then
                    s_ctr <= 0;
                end if;
                
                when DEC_DO => s_decrypting <= '1';
                
                when DEC_PROCESS_B =>
                s_ctr <= s_ctr + 1;
                if s_ctr = g_b - 1 then
                    s_ctr <= 0;
                end if;
                
                when FIN_PROCESS_A =>
                s_ctr <= s_ctr + 1;
                if s_ctr = g_a-1 then
                    s_ctr <= 0;
                end if;
                
                when others => null;
        end case;
    end if;
    
    -- in case CPU stops IP or reset
    if reset then
        s_ctr       <= 0;
        s_init_done <= '0';
        s_ad_done   <= '0';
        s_decrypting<= '0';
    end if;
    end process P_int_sig_logic;

end Behavioral;
