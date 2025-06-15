-- FSM overhaul

----------------------------------------------------------------------------------
-- Circuit Design for Security Exercise 1
-- ASCON-AEAD 128 NIST SP 800-232 ipd
-- (c) TUM
-- FOR EDUCATIONAL PURPOSE ONLY
----------------------------------------------------------------------------------
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
-- reg_My_Register : Register
--
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
    ASK_NEXT,
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
    ROUND_FIN,
    RETURN_TAG);
    
type t_step is(
    STANDING,
    INITIALIZATION,
    ASSOCIATED_DATA,
    PLAINTEXT,
    FINALIZATION);

signal s_state          : t_state;
signal s_step           : t_step;
signal s_ad             : std_logic;    -- handle associated data
signal s_write_buffer   : std_logic;    -- handle data write syncrhonization
signal s_round_counter  : integer;      -- handle round counting (could be avoided)

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
        if rising_edge(clk) then
            case s_state is
                when IDLE => if start then s_state <= WAIT_NONCE; end if;
                when ASK_NEXT =>
                case s_step is
                    when INITIALIZATION     => s_state <= WAIT_NONCE;
                    when ASSOCIATED_DATA    => s_state <= WAIT_INIT;
                    when PLAINTEXT          => s_state <= WAIT_FIN;
                    when others             => s_state <= IDLE;
                end case;
                
                -- Initialization
                when WAIT_NONCE     => if input_queue_blocktype = Nonce then s_state <= INIT_NONCE; else s_state <= IDLE; end if;
                when INIT_NONCE     => s_state <= ROUND_NONCE;
                when ROUND_NONCE    => if (to_integer(unsigned(round)) = g_a-1) then s_state <= INIT_KEY; end if;
                when INIT_KEY       => s_state <= ASK_NEXT;
                
                -- Transition after Initialization
                when WAIT_INIT =>
                if input_queue_blocktype = AData then s_state <= COMPUTE_AD; end if;
                if input_queue_blocktype = Message then 
                    if s_ad then s_state <= COMPUTE_ONE; else s_state <= COMPUTE_MESSAGE; end if;
                end if;
                
                -- Associated Data
                when COMPUTE_AD     => s_state <= ROUND_AD;
                when ROUND_AD       => if (to_integer(unsigned(round)) = g_a-1) then s_state <= ASK_NEXT; end if;
                when COMPUTE_ONE    => s_state <= COMPUTE_MESSAGE;
                
                -- Plaintext
                when COMPUTE_MESSAGE    => s_state <= ASK_NEXT;
                when ROUND_DEC          => if (to_integer(unsigned(round)) = g_a-1) then s_state <= COMPUTE_MESSAGE; end if;
                                
                -- Transition after Plaintext
                when WAIT_FIN =>
                if input_queue_blocktype = Message  then s_state <= ROUND_DEC; end if;
                if input_queue_blocktype = Tag      then s_state <= FIN_KEY; end if;
                    
                -- Finalization
                when FIN_KEY    => s_state <= ROUND_FIN; 
                when ROUND_FIN  => if (to_integer(unsigned(round)) = g_a-1) then s_state <= RETURN_TAG; end if;
                when RETURN_TAG => s_state <= IDLE;
                           
                when others => s_state <= IDLE;
            end case;
    
            -- in case CPU stops IP or reset
            if reset then s_state <= IDLE; end if;
       end if;
    end process P_next_state;

    -- Output logic
    P_output_logic : process (s_state)
    begin
        case s_state is
            when IDLE =>
                input_queue_next    <= '0';
                s_write_buffer      <= '0';
                valid               <= '0';
                ready               <= '0';
                operation           <= NOP;
            when ASK_NEXT =>
                input_queue_next    <= '1';
                s_write_buffer      <= '0';
                operation           <= NOP;
            when WAIT_NONCE =>
                input_queue_next    <= '0';
                s_write_buffer      <= '0';
                operation           <= NOP;
            when INIT_NONCE =>
                operation           <= Init;
            when ROUND_NONCE =>
                operation           <= applyRound;
            when INIT_KEY =>
                operation           <= applyKeyI;
            when WAIT_INIT =>
                input_queue_next    <= '0';
                s_write_buffer      <= '0';
                operation           <= NOP;
            when COMPUTE_AD =>
                operation           <= applyAD;
            when COMPUTE_MESSAGE =>
                input_queue_next    <= '0';
                s_write_buffer      <= '1';
                operation           <= applyDec;
            when ROUND_AD =>
                operation           <= applyRound;
            when COMPUTE_ONE =>
                operation           <= applyOne;
            when WAIT_FIN =>
                input_queue_next    <= '0';
                s_write_buffer      <= '0';
                operation           <= NOP;
            when ROUND_DEC =>
                operation           <= applyRound;
             when FIN_KEY =>
                operation           <= applyKeyF;
            when ROUND_FIN =>
                operation           <= applyRound;
            when RETURN_TAG =>
                valid               <= '1';
                ready               <= '1';
                operation           <= NOP;
            when others => null;
        end case;
    end process P_output_logic;
    
    -- Internal Signal logic
    -- also dedicated to round counter logic
    P_int_sig_logic : process (clk)
    begin
    if rising_edge(clk) then
        case s_state is
            -- handle associated data
            when IDLE =>
                s_ad                    <= '0'; 
                s_round_counter         <= 0;
                if start then s_step <= INITIALIZATION; end if;
                
            when COMPUTE_AD => s_ad <= '1';
            
            when INIT_KEY           => s_step <= ASSOCIATED_DATA;        
            when COMPUTE_MESSAGE    => s_step <= PLAINTEXT;
            when FIN_KEY            => s_step <= FINALIZATION;
            when RETURN_TAG         => s_step <= STANDING;
            
            when WAIT_INIT      => s_round_counter <= g_a - g_b;
            when WAIT_FIN       => s_round_counter <= g_a - g_b;
            when ROUND_NONCE    => s_round_counter <= s_round_counter + 1;
            when ROUND_AD       => s_round_counter <= s_round_counter + 1;
            when ROUND_DEC      => s_round_counter <= s_round_counter + 1;
            when ROUND_FIN      => s_round_counter <= s_round_counter + 1;
            
            when others => null;
        end case;
        
        -- in case CPU stops IP or reset
        if reset then
            s_ad            <= '0';
            s_round_counter <= 0;
            s_write_buffer  <= '0';
            s_step          <= STANDING;
        end if;
    end if;
    end process P_int_sig_logic;
    
    -- output queue write logic
    P_output_write : process(s_write_buffer)
    begin
    output_queue_write <= s_write_buffer;
    end process P_output_write;
    
round <= std_logic_vector(to_unsigned( s_round_counter, g_rnd_width));


end Behavioral;
