library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Test_komponent is
    port(
        reset_n, clock_50 : in std_logic;
        KEY : in std_logic_vector(1 downto 0);                   -- Push buttons controlling test patterns
        adress_vga_w : out std_logic_vector(16 downto 0);        -- Address to VGA write port
        data_vga_w : out std_logic_vector(2 downto 0);           -- Pixel data (RGB)
        write_VGA : out std_logic                                -- Write enable signal
    );
end entity;

architecture rtl of Test_komponent is

    --------------------------------------------------------------------
    -- Constants
    --------------------------------------------------------------------
    constant max_address : std_logic_vector(16 downto 0) := "10010101111111111";  
    -- Maximum framebuffer address (76 799 = 320*240 - 1)

    --------------------------------------------------------------------
    -- Internal signals
    --------------------------------------------------------------------
    signal address_counter : std_logic_vector(16 downto 0);  -- Linear pixel address
    signal y_count         : integer range 0 to 319;         -- Row counter (0–239)
    signal x_count         : integer range 0 to 239;         -- Column counter (0–319)
    signal count_en        : std_logic;                      -- Enable signal for address generation
    signal test_pettern    : std_logic_vector(1 downto 0);   -- Selected test pattern (00, 01, 10)

    --------------------------------------------------------------------
    -- FSM declaration
    --------------------------------------------------------------------
    type state_type is (Idle, Clear, KEY0_state, KEY1_state, WaitRelease);
    signal state : state_type;

begin

    --------------------------------------------------------------------
    -- FSM process: Controls test pattern generation and addressing
    --------------------------------------------------------------------
    process(clock_50, reset_n)
    begin
        if reset_n = '0' then
            state <= Clear;               -- Start by clearing RAM
            count_en <= '0';
            test_pettern <= "00";

        elsif rising_edge(clock_50) then
            case state is

                --------------------------------------------------------
                -- Clear entire framebuffer
                --------------------------------------------------------
                when Clear =>
                    count_en <= '1';
                    test_pettern <= "00";

                    if address_counter < max_address then
                        state <= Clear;   -- Keep clearing
                    else
                        state <= Idle;    -- Done clearing
                        count_en <= '0';
                    end if;

                --------------------------------------------------------
                -- Wait for user input (KEY)
                --------------------------------------------------------
                when Idle =>
                    if KEY = "10" then         -- KEY(1) pressed
                        test_pettern <= "10";  -- Pattern 2
                        count_en <= '1';
                        state <= KEY0_state;

                    elsif KEY = "01" then      -- KEY(0) pressed
                        test_pettern <= "01";  -- Pattern 1
                        count_en <= '1';
                        state <= KEY1_state;
                    end if;

                --------------------------------------------------------
                -- Generate Pattern for KEY = "10"
                --------------------------------------------------------
                when KEY0_state =>
                    if address_counter < max_address then
                        state <= KEY0_state;
                    else
                        count_en <= '0';
                        state <= WaitRelease;
                    end if;

                --------------------------------------------------------
                -- Generate Pattern for KEY = "01"
                --------------------------------------------------------
                when KEY1_state =>
                    if address_counter < max_address then
                        state <= KEY1_state;
                    else
                        count_en <= '0';
                        state <= WaitRelease;
                    end if;

                --------------------------------------------------------
                -- Wait until push button is released
                --------------------------------------------------------
                when WaitRelease =>
                    if KEY = "10" or KEY = "01" then
                        state <= WaitRelease;   -- Still pressed
                    else
                        state <= Idle;          -- Released
                    end if;

                when others =>
                    state <= Idle;
            end case;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Address generation for framebuffer
    --------------------------------------------------------------------
    process(clock_50, reset_n)
    begin
        if reset_n = '0' then
            y_count <= 0;
            x_count <= 0;

        elsif rising_edge(clock_50) then
            if address_counter < max_address and count_en = '1' then
                
                -- Move through the entire 320x240 image area
                if x_count = 319 then
                    x_count <= 0;
                    if y_count = 239 then
                        y_count <= 0;        -- Wrap around after last row
                    else
                        y_count <= y_count + 1;
                    end if;
                else
                    x_count <= x_count + 1;  -- Next column
                end if;

            else
                -- Reset counters when not enabled
                y_count <= 0;
                x_count <= 0;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------
    -- Concurrent assignments
    --------------------------------------------------------------------

    -- Convert (x, y) coordinates to linear RAM address
    address_counter <= std_logic_vector(to_unsigned(x_count + y_count * 320, address_counter'length));

    -- Output address, but clamp to zero if above max range
    adress_vga_w <= address_counter when address_counter <= max_address else (others => '0');

    -- Write enable: active-low (write when count_en = '1')
    write_VGA <= '0' when count_en = '1' else '1';

    --------------------------------------------------------------------
    -- Pixel generation for different test patterns
    --------------------------------------------------------------------

    -- RED pixel channel
    data_vga_w(0) <=  
        '0' when (x_count >= 0 and x_count <= 319) and (y_count >= 0 and y_count <= 239) and test_pettern = "00" else
        '1' when (x_count >= 0 and x_count <= 179) and (y_count >= 0 and y_count <= 159) and test_pettern = "10" else
        '1' when (((x_count = 160) and (y_count >= 0 and y_count <= 239)) or ((x_count >= 0 and x_count <= 319) and (y_count = 119))) and test_pettern = "01" else
        '1' when (((y_count >= 0 and y_count <= 239) and (x_count = 0)) or ((y_count >= 0 and y_count <= 239) and (x_count = 319))) and test_pettern = "01" else
        '0';

    -- GREEN pixel channel
    data_vga_w(1) <=  
        '0' when (x_count >= 0 and x_count <= 319) and (y_count >= 0 and y_count <= 239) and test_pettern = "00" else
        '1' when (x_count >= 0 and x_count <= 205) and (y_count >= 139 and y_count <= 239) and test_pettern = "10" else
        '1' when (((x_count = 160) and (y_count >= 0 and y_count <= 239)) or ((x_count >= 0 and x_count <= 319) and (y_count = 119))) and test_pettern = "01" else
        '1' when ((y_count = 239) and (x_count >= 0 and x_count <= 319)) and test_pettern = "01" else
        '0';

    -- BLUE pixel channel
    data_vga_w(2) <=  
        '0' when (x_count >= 0 and x_count <= 319) and (y_count >= 0 and y_count <= 239) and test_pettern = "00" else
        '1' when (x_count >= 149 and x_count <= 319) and (y_count >= 119 and y_count <= 239) and test_pettern = "10" else
        '1' when (((x_count = 160) and (y_count >= 0 and y_count <= 239)) or ((x_count >= 0 and x_count <= 319) and (y_count = 119))) and test_pettern = "01" else
        '1' when ((y_count = 0) and (x_count >= 0 and x_count <= 319)) and test_pettern = "01" else
        '0';

end architecture;
