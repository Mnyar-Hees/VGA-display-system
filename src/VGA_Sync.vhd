library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_Sync is
    port(
        data : in std_logic_vector(2 downto 0);               -- Pixel data (RGB: 3 bits)
        clk : in std_logic;                                   -- System clock (50 MHz or pixel clock)
        reset_n : in std_logic;                               -- Active-low reset
        VGA_HS : out std_logic;                               -- Horizontal sync signal
        VGA_VS : out std_logic;                               -- Vertical sync signal
        VGA_CLK : buffer std_logic;                           -- VGA pixel clock output
        VGA_R : out std_logic_vector(3 downto 0);             -- Red color output
        VGA_G : out std_logic_vector(3 downto 0);             -- Green color output
        VGA_B : out std_logic_vector(3 downto 0);             -- Blue color output
        status_sync_write : out std_logic;                    -- High when outside visible area
        address : out std_logic_vector(16 downto 0)           -- Calculated pixel address
    );
end entity;

architecture rtl of VGA_Sync is

    --------------------------------------------------------------------
    -- VGA Timing Constants (640x480 @ 60Hz)
    -- These include front porch, sync pulse width, and back porch.
    --------------------------------------------------------------------
    constant H_SYNC_CYCLES : integer := 800;    -- Total horizontal cycles per line
    constant V_SYNC_CYCLES : integer := 525;    -- Total vertical lines per frame

    -- Horizontal timing
    constant H_SYNC_FRONT : integer := 40;
    constant H_SYNC_SYNC  : integer := 96;
    constant H_SYNC_BACK  : integer := 48;

    -- Vertical timing
    constant V_SYNC_FRONT : integer := 1;
    constant V_SYNC_SYNC  : integer := 2;
    constant V_SYNC_BACK  : integer := 33;

    --------------------------------------------------------------------
    -- Internal counters
    -- h_counter: pixel position within a line
    -- v_counter: line position within a frame
    --------------------------------------------------------------------
    signal h_counter : integer range 0 to H_SYNC_CYCLES - 1 := 0;
    signal v_counter : integer range 0 to V_SYNC_CYCLES - 1 := 0;

begin

    --------------------------------------------------------------------
    -- Expand incoming 3-bit RGB into 4-bit VGA output channels
    --------------------------------------------------------------------
    VGA_R <= (others => data(2));   -- Red channel = data(2) repeated
    VGA_G <= (others => data(1));   -- Green channel = data(1) repeated
    VGA_B <= (others => data(0));   -- Blue channel = data(0) repeated

    --------------------------------------------------------------------
    -- Horizontal and Vertical Counters
    -- Generates positions across an 800x525 VGA timing frame.
    --------------------------------------------------------------------
    process(clk, reset_n)
    begin
        if reset_n = '0' then
            -- Reset counters
            h_counter <= 0;
            v_counter <= 0;

        elsif rising_edge(clk) then

            ----------------------------------------------------------------
            -- Horizontal counter (0–799)
            ----------------------------------------------------------------
            if h_counter >= 799 then
                h_counter <= 0;
            else
                h_counter <= h_counter + 1;
            end if;

            ----------------------------------------------------------------
            -- Vertical counter increments when horizontal wraps at 707
            -- NOTE: The value 707 is chosen based on original student design.
            ----------------------------------------------------------------
            if h_counter = 707 then
                if v_counter = 524 then
                    v_counter <= 0;
                else
                    v_counter <= v_counter + 1;
                end if;
            end if;

        end if;
    end process;

    --------------------------------------------------------------------
    -- Sync Pulse Generation
    -- Active-low sync signals based on counter ranges.
    --------------------------------------------------------------------
    VGA_HS <= '0' when h_counter > 659 and h_counter < 756 else '1';
    VGA_VS <= '0' when v_counter = 494                     else '1';

    --------------------------------------------------------------------
    -- Pixel Clock Output (simply forwarded)
    --------------------------------------------------------------------
    VGA_CLK <= clk;

    --------------------------------------------------------------------
    -- Write Status
    -- High when outside visible area (not reading from framebuffer)
    --------------------------------------------------------------------
    status_sync_write <= '0' when h_counter < 640 and v_counter < 480 else '1';

    --------------------------------------------------------------------
    -- Framebuffer Address Calculation
    -- Converts downscaled (640x480) counters to 320x240 resolution.
    -- Division by 2 maps VGA pixels to your framebuffer size.
    --------------------------------------------------------------------
    address <= std_logic_vector(
                    to_unsigned((v_counter / 2) * 320 + (h_counter / 2), 17)
               )
        when (h_counter < 640 and v_counter < 480)
        else (others => '0');

end architecture;
