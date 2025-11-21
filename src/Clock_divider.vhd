library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Clock_Divider is
    port(
        clock_50 : in std_logic;      -- 50 MHz system clock input
        reset_n  : in std_logic;      -- Active-low synchronous reset
        clock_25 : out std_logic      -- 25 MHz output clock
    );
end entity;

architecture rtl of Clock_Divider is

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal count : integer range 0 to 1 := 0;   -- 2-state counter for division-by-2
    signal clock_25_int : std_logic := '0';     -- Internal 25 MHz clock

begin

    --------------------------------------------------------------------
    -- Clock Divider Process
    -- Divides the 50 MHz input clock by 2 to produce a 25 MHz clock.
    -- This is required by the VGA timing (pixel clock).
    --------------------------------------------------------------------
    process(clock_50, reset_n)
    begin
        if reset_n = '0' then
            count <= 0;
            clock_25_int <= '0';

        elsif rising_edge(clock_50) then
            count <= count + 1;

            -- Toggle the output clock every 2 cycles of the 50 MHz clock
            if count = 1 then
                clock_25_int <= not clock_25_int;
                count <= 0;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Assign internal clock to output
    --------------------------------------------------------------------
    clock_25 <= clock_25_int;

end architecture;
