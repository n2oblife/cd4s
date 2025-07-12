library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-------------------------------------------------------------------------------------------------
-- FUNCTIONS
-------------------------------------------------------------------------------------------------
-- Function to check if a std_logic_vector equals 1
-- function is_one(signal vec : std_logic_vector) return boolean is
-- begin
--     return vec(0) = '1' and vec(vec'high downto 1) = (vec'high downto 1 => '0');
-- end function is_one;

-- Alternative approach: Use constant ONE for comparison
-- if reg_u = ONE then

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

-------------------------------------------------------------------------------------------------
-- SIGNALS
-------------------------------------------------------------------------------------------------
type state_type is (IDLE, CHECK_U_EVEN, CHECK_V_EVEN, COMPARE_UV, UPDATE_U, UPDATE_V, DONE_STATE);
signal current_state, next_state : state_type;

-- Constants
constant ONE : STD_LOGIC_VECTOR(input_width-1 downto 0) := (0 => '1', others => '0');

-- Main algorithm variables
signal reg_u, reg_v : STD_LOGIC_VECTOR(input_width-1 downto 0);
signal reg_x1, reg_x2 : STD_LOGIC_VECTOR(input_width-1 downto 0);

-- Adder control and results
signal adder1_a, adder1_b : STD_LOGIC_VECTOR(input_width-1 downto 0);
signal adder1_neg_b : STD_LOGIC;
signal adder1_result : STD_LOGIC_VECTOR(input_width downto 0);

signal adder2_a, adder2_b : STD_LOGIC_VECTOR(input_width-1 downto 0);
signal adder2_neg_b : STD_LOGIC;
signal adder2_result : STD_LOGIC_VECTOR(input_width downto 0);

-- Control signals
signal u_is_even, v_is_even : STD_LOGIC;
signal x1_is_even, x2_is_even : STD_LOGIC;
signal u_geq_v : STD_LOGIC;
signal u_is_one, v_is_one : STD_LOGIC;

begin

-------------------------------------------------------------------------------------------------
-- MAPPING
-------------------------------------------------------------------------------------------------

-- Main adder for u/v operations
main_adder : adder
generic map(
    input_width => input_width
)
port map(
    a     => adder1_a,
    b     => adder1_b,
    neg_b => adder1_neg_b,      
    s     => adder1_result
);

-- Secondary adder for x1/x2 operations
x_adder : adder
generic map(
    input_width => input_width
)
port map(
    a     => adder2_a,
    b     => adder2_b,
    neg_b => adder2_neg_b,      
    s     => adder2_result
);

-------------------------------------------------------------------------------------------------
-- COMBINATIONAL LOGIC
-------------------------------------------------------------------------------------------------

-- Even/odd checks
u_is_even <= '1' when reg_u(0) = '0' else '0';
v_is_even <= '1' when reg_v(0) = '0' else '0';
x1_is_even <= '1' when reg_x1(0) = '0' else '0';
x2_is_even <= '1' when reg_x2(0) = '0' else '0';

-- Check if equals 1
u_is_one <= '1' when reg_u = ONE else '0';
v_is_one <= '1' when reg_v = ONE else '0';

-- Compare u >= v using the adder (subtraction)
u_geq_v <= not adder1_result(input_width) when current_state = COMPARE_UV else '0';

-------------------------------------------------------------------------------------------------
-- SEQUENTIAL LOGIC
-------------------------------------------------------------------------------------------------

-- State register process
process(clk, reset)
begin
    if reset = '1' then
        current_state <= IDLE;
        reg_u <= (others => '0');
        reg_v <= (others => '0');
        reg_x1 <= (others => '0');
        reg_x2 <= (others => '0');
        done <= '0';
        inverse <= (others => '0');
    elsif rising_edge(clk) then
        current_state <= next_state;
        
        case current_state is
            when IDLE =>
                if input_r = '1' then
                    reg_u <= u;
                    reg_v <= v;
                    reg_x1 <= (0 => '1', others => '0');  -- x1 = 1
                    reg_x2 <= (others => '0');            -- x2 = 0
                    done <= '0';
                end if;
                
            when CHECK_U_EVEN =>
                if u_is_even = '1' then
                    reg_u <= '0' & reg_u(input_width-1 downto 1);  -- u = u/2
                    if x1_is_even = '1' then
                        reg_x1 <= '0' & reg_x1(input_width-1 downto 1);  -- x1 = x1/2
                    else
                        reg_x1 <= adder2_result(input_width-1 downto 0);  -- x1 = (x1 + p)/2
                    end if;
                end if;
                
            when CHECK_V_EVEN =>
                if v_is_even = '1' then
                    reg_v <= '0' & reg_v(input_width-1 downto 1);  -- v = v/2
                    if x2_is_even = '1' then
                        reg_x2 <= '0' & reg_x2(input_width-1 downto 1);  -- x2 = x2/2
                    else
                        reg_x2 <= adder2_result(input_width-1 downto 0);  -- x2 = (x2 + p)/2
                    end if;
                end if;
                
            when UPDATE_U =>
                reg_u <= adder1_result(input_width-1 downto 0);    -- u = u - v
                reg_x1 <= adder2_result(input_width-1 downto 0);   -- x1 = x1 - x2
                
            when UPDATE_V =>
                reg_v <= adder1_result(input_width-1 downto 0);    -- v = v - u
                reg_x2 <= adder2_result(input_width-1 downto 0);   -- x2 = x2 - x1
                
            when DONE_STATE =>
                done <= '1';
                if reg_u = ONE then
                    inverse <= reg_x1;
                else
                    inverse <= reg_x2;
                end if;
                
            when others =>
                null;
        end case;
    end if;
end process;

-- Next state logic
process(current_state, input_r, u_is_even, v_is_even, u_geq_v, reg_u, reg_v)
begin
    -- Default assignments
    next_state <= current_state;
    adder1_a <= reg_u;
    adder1_b <= reg_v;
    adder1_neg_b <= '0';
    adder2_a <= reg_x1;
    adder2_b <= reg_x2;
    adder2_neg_b <= '0';
    
    case current_state is
        when IDLE =>
            if input_r = '1' then
                next_state <= CHECK_U_EVEN;
            end if;
            
        when CHECK_U_EVEN =>
            if u_is_even = '1' then
                -- Setup for (x1 + p)/2 calculation if needed
                if not x1_is_even then
                    adder2_a <= reg_x1;
                    adder2_b <= v;  -- v is p in our case
                    adder2_neg_b <= '0';
                end if;
                next_state <= CHECK_U_EVEN;  -- Stay to keep dividing by 2
            else
                next_state <= CHECK_V_EVEN;
            end if;
            
        when CHECK_V_EVEN =>
            if v_is_even = '1' then
                -- Setup for (x2 + p)/2 calculation if needed
                if not x2_is_even then
                    adder2_a <= reg_x2;
                    adder2_b <= v;  -- v is p in our case
                    adder2_neg_b <= '0';
                end if;
                next_state <= CHECK_V_EVEN;  -- Stay to keep dividing by 2
            else
                next_state <= COMPARE_UV;
            end if;
            
        when COMPARE_UV =>
            -- Setup for u - v comparison
            adder1_a <= reg_u;
            adder1_b <= reg_v;
            adder1_neg_b <= '1';
            
            -- if is_one(reg_u) or is_one(reg_v) then
            if reg_u = ONE or reg_v = ONE then
                next_state <= DONE_STATE;
            else
                next_state <= UPDATE_U when u_geq_v = '1' else UPDATE_V;
            end if;
            
            -- Alternative using combinational signals:
            -- if u_is_one = '1' or v_is_one = '1' then
            --     next_state <= DONE_STATE;
            -- else
            --     next_state <= UPDATE_U when u_geq_v = '1' else UPDATE_V;
            -- end if;
            
        when UPDATE_U =>
            -- Setup for u = u - v
            adder1_a <= reg_u;
            adder1_b <= reg_v;
            adder1_neg_b <= '1';
            -- Setup for x1 = x1 - x2
            adder2_a <= reg_x1;
            adder2_b <= reg_x2;
            adder2_neg_b <= '1';
            next_state <= CHECK_U_EVEN;
            
        when UPDATE_V =>
            -- Setup for v = v - u
            adder1_a <= reg_v;
            adder1_b <= reg_u;
            adder1_neg_b <= '1';
            -- Setup for x2 = x2 - x1
            adder2_a <= reg_x2;
            adder2_b <= reg_x1;
            adder2_neg_b <= '1';
            next_state <= CHECK_V_EVEN;
            
        when DONE_STATE =>
            next_state <= IDLE;
            
    end case;
end process;

end Behavioral;
