-- FSM overhaul

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

type t_state is(
    IDLE, 
    WAIT_NONCE, 
    INIT_NONCE, 
    ROUND_NONCE, 
    INIT_KEY, 
    WAIT_INIT, 
    COMPUTE_AD, 
    COMPUTE_MESSAGE, 
    ROUND_AD,
    COMPUTE_ONE,
    WAIT_FIN,
    ROUND_DEC,
    FIN_KEY,
    FIN_ROUND,
    RETURN_TAG);

signal s_state : t_state;

signal s_ad : std_logic; -- handle associated data

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
                when IDLE => if start then s_state <= WAIT_NONCE; end if;
                
                -- Initialization
                when WAIT_NONCE => if input_queue_blocktype = Nonce then s_state <= INIT_NONCE; end if;
                when INIT_NONCE => s_state <= ROUND_NONCE;
                when ROUND_NONCE => if (to_integer(unsigned(round)) = g_a-1) then s_state <= INIT_KEY; end if;
                when INIT_KEY => s_state <= WAIT_INIT;
                
                -- Transition after Initialization
                when WAIT_INIT =>
                if input_queue_blocktype = AData    then s_state <= COMPUTE_AD; end if;
                if input_queue_blocktype = Message then 
                    if s_ad then s_state <= COMPUTE_ONE; else s_state <= COMPUTE_MESSAGE; end if;
                end if;
                
                -- Associated Data
                when COMPUTE_AD => s_state <= ROUND_AD;
                when ROUND_AD => if (to_integer(unsigned(round)) = g_b-1) then s_state <= WAIT_INIT; end if;
                when COMPUTE_ONE => s_state <= COMPUTE_MESSAGE;
                
                -- Plaintext
                when COMPUTE_MESSAGE => s_state <= WAIT_FIN;
                when ROUND_DEC => if (to_integer(unsigned(round)) = g_b-1) then s_state <= COMPUTE_MESSAGE; end if;
                                
                -- Transition after Plaintext
                when WAIT_FIN =>
                if input_queue_blocktype = Message then s_state <= ROUND_DEC; end if;
                if input_queue_blocktype = Tag then s_state <= FIN_KEY; end if;
                    
                -- Finalization
                when FIN_KEY => s_state <= FIN_ROUND; 
                when FIN_ROUND =>if (to_integer(unsigned(round)) = g_a-1) then s_state <= RETURN_TAG; end if;
                when RETURN_TAG => s_state <= IDLE;
                           
                when others => s_state <= IDLE;
            end case;

            -- in case CPU stops IP or reset
            if reset then s_state <= IDLE; end if;

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
            when WAIT_NONCE =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when INIT_NONCE =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= Init;
                round               <= (others => '0');
            when ROUND_NONCE =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= round + std_logic_vector(to_unsigned(1, g_rd_width));
            when INIT_KEY =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyKeyI;
                round               <= (others => '0');
            when WAIT_INIT =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when COMPUTE_AD =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyAD;
                round               <= (others => '0');
            when COMPUTE_MESSAGE =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyDec;
                round               <= (others => '0');
            when ROUND_AD =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= (others => '0');
            when COMPUTE_ONE =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyOne;
                round               <= (others => '0');
            when WAIT_FIN =>
                input_queue_next    <= '1';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
                round               <= (others => '0');
            when ROUND_DEC =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= (others => '0');
             when FIN_KEY =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyKeyF;
                round               <= (others => '0');
            when FIN_ROUND =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= applyRound;
                round               <= (others => '0');
            when RETURN_TAG =>
                input_queue_next    <= '0';
                output_queue_write  <= '0';
                valid               <= '1';
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
            -- handle associated data
            when IDLE       => s_ad <= '0';
            when COMPUTE_AD => s_ad <= '1';    
            when others     => null;
        end case;
    end if;
    
    -- in case CPU stops IP or reset
    if reset then
        s_ad <= '0';
    end if;
    end process P_int_sig_logic;

end Behavioral;
