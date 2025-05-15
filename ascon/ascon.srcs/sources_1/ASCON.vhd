----------------------------------------------------------------------------------
-- Circuit Design for Security Exercise 1
-- ASCON-AEAD 128 NIST SP 800-232 ipd
-- (c) TUM
-- FOR EDUCATIONAL PURPOSE ONLY
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity Rotate is
    Generic ( c1 : natural;
              c2 : natural );
    Port ( si : in STD_LOGIC_VECTOR (63 downto 0);
           so : out STD_LOGIC_VECTOR (63 downto 0) );
end Rotate;
architecture Behavioral of Rotate is
begin
so(63 downto 0) <= si(63 downto 0) xor (si(c1-1 downto 0) & si(63 downto c1)) xor (si(c2-1 downto 0) & si(63 downto c2));
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity SBox is
    Port ( si : in STD_LOGIC_VECTOR (4 downto 0);
           so : out STD_LOGIC_VECTOR (4 downto 0) );
end SBox;
architecture Behavioral of SBox is
signal t1 : std_logic_vector (4 downto 0);
signal t2 : std_logic_vector (4 downto 0);
signal t3 : std_logic_vector (4 downto 0);
begin
t1(4 downto 0) <= si(4 downto 0) xor (si(3) & '0' & si(1) & '0' & si(4));
t2(4 downto 0) <= (not t1(4 downto 0)) and (t1(0) & t1(4 downto 1));
t3(4 downto 0) <= t1(4 downto 0) xor (t2(0) & t2(4 downto 1));
so(4 downto 0) <= t3(4 downto 0) xor ('0' & t3(2) & '1' & t3(0) & t3(4));
end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Common.all;
entity ParallelSBox is
    Port ( si : in STD_LOGIC_VECTOR (319 downto 0);
           so : out STD_LOGIC_VECTOR (319 downto 0) );
end ParallelSBox;
architecture Behavioral of ParallelSBox is
begin
Generate_SBox : for I in 0 to 63 generate
    SBox_instance : entity work.SBox
    port map(si(0) => si(I), si(1) => si(I+64), si(2) => si(I+128), si(3) => si(I+192), si(4) => si(I+256),
             so(0) => so(I), so(1) => so(I+64), so(2) => so(I+128), so(3) => so(I+192), so(4) => so(I+256));
end generate;
end Behavioral;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Common.all;
entity ParallelRotate is
    Port ( si : in STD_LOGIC_VECTOR (319 downto 0);
           so : out STD_LOGIC_VECTOR (319 downto 0) );
end ParallelRotate;
architecture Behavioral of ParallelRotate is
begin
Rotate_instance_0 : entity work.Rotate
    generic map(c1 => 19, c2 => 28)
    port map(si(63 downto 0) => si(63 downto 0), so(63 downto 0) => so(63 downto 0));
Rotate_instance_1 : entity work.Rotate
    generic map(c1 => 61, c2 => 39)
    port map(si(63 downto 0) => si(127 downto 64), so(63 downto 0) => so(127 downto 64));
Rotate_instance_2 : entity work.Rotate
    generic map(c1 => 1, c2 => 6)
    port map(si(63 downto 0) => si(191 downto 128), so(63 downto 0) => so(191 downto 128));
Rotate_instance_3 : entity work.Rotate
    generic map(c1 => 10, c2 => 17)
    port map(si(63 downto 0) => si(255 downto 192), so(63 downto 0) => so(255 downto 192));
Rotate_instance_4 : entity work.Rotate
    generic map(c1 => 7, c2 => 41)
    port map(si(63 downto 0) => si(319 downto 256), so(63 downto 0) => so(319 downto 256));
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.Common.all;
entity ASCON is
    Port (  clk : in STD_LOGIC;
            reset : in STD_LOGIC;
            start : in STD_LOGIC;
            key_reg : in STD_LOGIC_VECTOR (127 downto 0);
           
            input_queue_out : in STD_LOGIC_VECTOR (127 downto 0);
            input_queue_blocktype : in blocktype;
            input_queue_next : out STD_LOGIC;
           
            output_queue_in : out STD_LOGIC_VECTOR (127 downto 0);
            output_queue_write : out STD_LOGIC;

            valid : out STD_LOGIC;
            ready : out STD_LOGIC
           );
end ASCON;

architecture Behavioral of ASCON is

constant IV : STD_LOGIC_VECTOR (63 downto 0) := x"00001000808c0001";
signal round : STD_LOGIC_VECTOR (3 downto 0);
signal tagsEqual : STD_LOGIC;
signal state : STD_LOGIC_VECTOR (319 downto 0);
signal next_state : STD_LOGIC_VECTOR (319 downto 0);
signal state_init : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyRound : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyADEnc : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyDec : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyKeyI : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyKeyF : STD_LOGIC_VECTOR (319 downto 0);
signal state_applyOne : STD_LOGIC_VECTOR (319 downto 0);
signal state_addRC : STD_LOGIC_VECTOR (319 downto 0);
signal state_SBox : STD_LOGIC_VECTOR (319 downto 0);
signal state_Rotated : STD_LOGIC_VECTOR (319 downto 0);

signal operation : Opcodes;

begin

state_init(319 downto 0) <= input_queue_out & key_reg & IV;
state_applyKeyI(319 downto 0) <= (state(319 downto 192) xor key_reg(127 downto 0)) & state(191 downto 0);
state_applyKeyF(319 downto 0) <= state(319 downto 256) & (state(255 downto 128) xor key_reg(127 downto 0)) & state(127 downto 1) & (state(0) xor '1');
state_applyOne(319 downto 0) <= (state(319) xor '1') & state(318 downto 0);
state_applyRound(319 downto 0) <= state_Rotated(319 downto 0);
state_applyADEnc(319 downto 0) <= state(319 downto 128) & (state(127 downto 0) xor input_queue_out(127 downto 0));
state_applyDec(319 downto 0) <= state(319 downto 128) & input_queue_out(127 downto 0);


with operation select
   next_state(319 downto 0) <= state_init(319 downto 0) when Init,
       state_applyRound(319 downto 0) when applyRound,
       state_applyADEnc(319 downto 0) when applyAD, 
       state_applyDec(319 downto 0) when applyDec, 
       state_applyKeyI(319 downto 0) when applyKeyI,
       state_applyKeyF(319 downto 0) when applyKeyF,
       state_applyOne(319 downto 0) when applyOne,
       state(319 downto 0) when others;

with operation select
   output_queue_in(127 downto 0) <= state(127 downto 0) xor input_queue_out(127 downto 0) when applyDec,
       (others => 'Z') when others;

       
process(all)
begin
if rising_edge(clk) then
    state(319 downto 0) <= next_state(319 downto 0);
end if;
end process;

process(all)
begin
if input_queue_out(127 downto 0) = (state(319 downto 192) xor key_reg(127 downto 0)) then
    tagsEqual <= '1';
    else
    tagsEqual <= '0';
end if;
end process;


state_addRC(319 downto 0) <= state(319 downto 136) & (state(135 downto 132) xor (not round))& (state(131 downto 128) xor round) & state(127 downto 0);

SBox_instance : entity work.ParallelSBox
    port map(si => state_addRC, so => state_SBox);

Rotate_instance : entity work.ParallelRotate
    port map(si => state_SBox, so => state_Rotated);

Control : entity work.FSM
    port map(clk => clk, 
    reset => reset,
    start => start,
    tagsEqual => tagsEqual,
    input_queue_next => input_queue_next,
    input_queue_blocktype => input_queue_blocktype,
    output_queue_write => output_queue_write,
    valid => valid,
    ready => ready,
    operation => operation,
    round => round);

           
end Behavioral;
