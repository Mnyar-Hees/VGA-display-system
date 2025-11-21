library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_component is
    port(
        reset_n : in std_logic;                     -- Active-low reset signal
        clock_50 : in std_logic;                    -- 50 MHz system clock
        VGA_HS : out std_logic;                     -- Horizontal sync signal
        VGA_VS : out std_logic;                     -- Vertical sync signal
        VGA_CLK : out std_logic;                    -- VGA pixel clock
        VGA_R : out std_logic_vector(3 downto 0);   -- Red color output
        VGA_G : out std_logic_vector(3 downto 0);   -- Green color output
        VGA_B : out std_logic_vector(3 downto 0);   -- Blue color output
        address_vga_w : in std_logic_vector(16 downto 0); -- Write address input
        data_vga_w : in std_logic_vector(2 downto 0);     -- Write pixel data (RGB)
        write_VGA : in std_logic;                   -- Write enable signal
        status_sync_write : out std_logic           -- Write status output
    );
end entity;

architecture rtl of VGA_component is

    --------------------------------------------------------------------
    -- VGA timing counters and internal video data/address signals
    --------------------------------------------------------------------
    signal h_count : integer range 0 to 799 := 0;   -- Horizontal counter
    signal v_count : integer range 0 to 524 := 0;   -- Vertical counter
    signal vga_data : std_logic_vector(2 downto 0);       -- Pixel data to VGA_Sync
    signal vga_address : std_logic_vector(16 downto 0);   -- Address to VGA_Sync

    --------------------------------------------------------------------
    -- Internal signals connected to instantiated components
    --------------------------------------------------------------------
    signal clock_25 : std_logic;                        -- 25 MHz pixel clock
    signal valid_pixel : std_logic;                     -- Pixel validity flag
    signal data_b : std_logic_vector(2 downto 0);       -- Read data from RAM
    signal status_sync_write_ram : std_logic;           -- Write status from RAM

    --------------------------------------------------------------------
    -- DualPort_RAM Component Declaration
    --------------------------------------------------------------------
    component DualPort_RAM is
        port(
            clk_a             : in std_logic;               -- Write clock
            clk_b             : in std_logic;               -- Read clock
            addr_a            : in std_logic_vector(16 downto 0); -- Write address
            data_a            : in std_logic_vector(2 downto 0);  -- Write data
            addr_b            : in std_logic_vector(16 downto 0); -- Read address
            reset_n           : in std_logic;               -- Reset
            write_en_a        : in std_logic := '0';        -- Write enable for port A
            data_b            : out std_logic_vector(2 downto 0); -- Read data output
            status_sync_write : out std_logic               -- Write status output
        );
    end component;

    --------------------------------------------------------------------
    -- Clock_Divider Component Declaration
    --------------------------------------------------------------------
    component Clock_Divider is
        port(
            clock_50 : in std_logic;   -- Input: 50 MHz clock
            reset_n : in std_logic;    -- Active-low reset
            clock_25 : out std_logic   -- Output: 25 MHz clock
        );
    end component;

    --------------------------------------------------------------------
    -- VGA_Sync Component Declaration
    --------------------------------------------------------------------
    component VGA_Sync is
        port(
            data    : in std_logic_vector(2 downto 0);       -- Pixel data input
            clk     : in std_logic;                          -- 50 MHz system clock
            reset_n : in std_logic;                          -- Active-low reset
            VGA_HS  : out std_logic;                         -- Horizontal sync
            VGA_VS  : out std_logic;                         -- Vertical sync
            VGA_CLK : buffer std_logic;                      -- VGA pixel clock output
            VGA_R   : out std_logic_vector(3 downto 0);      -- Red output
            VGA_G   : out std_logic_vector(3 downto 0);      -- Green output
            VGA_B   : out std_logic_vector(3 downto 0);      -- Blue output
            status_sync_write : out std_logic;               -- High when RAM is not being read
            address : out std_logic_vector(16 downto 0)      -- Pixel address output
        );
    end component;

begin

    --------------------------------------------------------------------
    -- Dual-Port RAM instance (framebuffer memory)
    --------------------------------------------------------------------
    ram_inst : DualPort_RAM
        port map(
            clk_a => clock_50,                -- Write clock (50 MHz)
            clk_b => clock_25,                -- Read clock (25 MHz)
            addr_a => address_vga_w,          -- Write address from Test component
            data_a => data_vga_w,             -- Write data (RGB)
            addr_b => vga_address,            -- Read address from VGA_Sync
            data_b => data_b,                 -- Read pixel data
            reset_n => reset_n,               -- Active-low reset
            write_en_a => write_VGA,          -- Write strobe
            status_sync_write => status_sync_write_ram  -- Write status output
        );

    --------------------------------------------------------------------
    -- Clock divider instance (50 MHz → 25 MHz)
    --------------------------------------------------------------------
    clock_div_inst : Clock_Divider
        port map(
            clock_50 => clock_50,     -- System clock input
            reset_n => reset_n,       -- Active-low reset
            clock_25 => clock_25      -- Generated 25 MHz clock
        );

    --------------------------------------------------------------------
    -- VGA synchronization and pixel generation
    --------------------------------------------------------------------
    vga_sync_inst : VGA_Sync
        port map(
            clk => clock_50,                 -- System clock (50 MHz)
            reset_n => reset_n,              -- Active-low reset
            VGA_HS => VGA_HS,                -- Horizontal sync output
            VGA_VS => VGA_VS,                -- Vertical sync output
            VGA_CLK => VGA_CLK,              -- VGA pixel clock output
            status_sync_write => status_sync_write, -- Write status forwarding
            address => vga_address,          -- Pixel address to RAM
            data => data_b,                  -- Pixel data from RAM
            VGA_R => VGA_R,                  -- Red output
            VGA_G => VGA_G,                  -- Green output
            VGA_B => VGA_B                   -- Blue output
        );

end rtl;
