library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DualPort_RAM is
    port(
        clk_a  : in std_logic;              -- Skrivklocka
        clk_b  : in std_logic;              -- Läsklocka
        addr_a : in std_logic_vector(16 downto 0); -- Adress för skrivning
        data_a : in std_logic_vector(2 downto 0);  -- Data för skrivning
        addr_b : in std_logic_vector(16 downto 0); -- Adress för läsning
        reset_n : in std_logic;            -- Reset
        write_en_a : in std_logic;         -- Skrivaktivering för port A
		  data_b : out std_logic_vector(2 downto 0); -- Lästa data
        status_sync_write : out std_logic  -- Status för skrivning
    );
end entity;

architecture rtl of DualPort_RAM is
    type ram_type is array(0 to 65535) of std_logic_vector(2 downto 0);
    signal ram : ram_type; -- Remove initialization

begin

    -- Process för att skriva till RAM på port A
    process(clk_a, reset_n)
    begin
        if rising_edge(clk_a) then
            if reset_n = '0' then
                -- Initialize RAM here if needed
            elsif write_en_a = '1' then
                ram(to_integer(unsigned(addr_a))) <= data_a;
            end if;
        end if;
    end process;

    -- Process för att läsa från RAM på port B
    process(clk_b)
    begin
        if rising_edge(clk_b) then
            data_b <= ram(to_integer(unsigned(addr_b)));
        end if;
    end process;

    -- Process för att uppdatera skrivstatus
    process(clk_a)
    begin
        if rising_edge(clk_a) then
            status_sync_write <= write_en_a;
        end if;
    end process;

end architecture;
