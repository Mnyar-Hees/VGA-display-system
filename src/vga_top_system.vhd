-- Engineer: Mnyar Hee
--
-- Project Description:
-- This top-level entity implements the complete VGA display system used in
-- assignment 2b. The system integrates a test stimulus generator and a 
-- reusable VGA display subsystem. Its purpose is to validate write operations
-- to a Dual-Port RAM framebuffer and verify the visual output on a VGA monitor.
--
-- System Overview:
--  - The Test_component generates two test patterns (Test Case 1 and Test Case 2),
--    activated via external push buttons. These patterns are written into the
--    VGA framebuffer through the memory write interface (address, data, write_VGA).
--
--  - The VGA_component is responsible for:
--       * VGA timing generation (HS, VS, VGA pixel clock)
--       * Reading pixel data from a True Dual-Port RAM (port A)
--       * Writing pixel data from the Test_component (port B)
--       * Synchronization control via status_sync_write
--       * Displaying 320x240 resolution using 3-bit RGB pixel format
--
--  - The Dual-Port RAM serves as the graphics memory (320 * 240 * 3 bits),
--    allowing simultaneous read and write operations using different clocks
--    (25 MHz for VGA read side and 50 MHz for write/test side).
--
--  - A clock divider or PLL is used to generate the 25 MHz VGA pixel clock.
--    The design is structured so that the clock source can easily be swapped
--    between a VHDL divider and a PLL implementation.
--
--  - All asynchronous inputs (buttons, reset) must be protected from
--    metastability by using two-stage synchronizers, as required in the 
--    assignment specification.
--
-- Purpose of this Top-Level File:
-- This file contains no internal functional logic. It simply connects 
-- board-level signals (reset, system clock, VGA outputs and memory write
-- interface) to the underlying VGA_component, which implements the entire
-- video pipeline and memory interface logic.
--
-- Architecture:
--   External I/O  -->  Test_top_system  -->  VGA_component  --> VGA Display
--
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity vga_top_system is
    port(
        reset_n : in std_logic;                         -- Active-low reset
        clock_50 : in std_logic;                        -- 50 MHz system clock

        VGA_HS : out std_logic;                         -- Horizontal sync
        VGA_VS : out std_logic;                         -- Vertical sync
        VGA_CLK : out std_logic;                        -- VGA pixel clock

        VGA_R : out std_logic_vector(3 downto 0);       -- Red color channel
        VGA_G : out std_logic_vector(3 downto 0);       -- Green color channel
        VGA_B : out std_logic_vector(3 downto 0);       -- Blue color channel

        address_vga_w : in std_logic_vector(16 downto 0); -- Write address to DP-RAM
        data_vga_w : in std_logic_vector(2 downto 0);     -- Write pixel data
        write_VGA : in std_logic;                         -- Write enable
        status_sync_write : out std_logic                 -- Sync status (high = safe to write)
    );
end entity vga_top_system;

architecture rtl of vga_top_system is
begin

    ---------------------------------------------------------------------
    -- Instantiation of the VGA component
    -- All signals are passed directly to the VGA_component.
    ---------------------------------------------------------------------
    VGA_inst : entity work.VGA_component
        port map(
            reset_n => reset_n,
            clock_50 => clock_50,

            VGA_HS => VGA_HS,
            VGA_VS => VGA_VS,
            VGA_CLK => VGA_CLK,

            VGA_R => VGA_R,
            VGA_G => VGA_G,
            VGA_B => VGA_B,

            address_vga_w => address_vga_w,  -- Write address
            data_vga_w => data_vga_w,        -- Pixel data
            write_VGA => write_VGA,          -- Write strobe
            status_sync_write => status_sync_write
        );

end architecture rtl;