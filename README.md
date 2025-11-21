VGA Display System (FPGA — VHDL)

This project implements a complete VGA display pipeline for 320×240 resolution on an FPGA using a dual-port framebuffer, 25 MHz pixel clock, VGA sync generator and automated test pattern generator.
The system was developed in VHDL and verified using ModelSim and the Intel MAX10 FPGA (DE10-Lite board).
System Architecture : 
Test_komponent 
      ↓ (address, data, write)
DualPort_RAM ←→ VGA_Sync ←→ VGA Monitor
      ↑ (read)
Clock_Divider (50 MHz → 25 MHz)
Top-level: vga_top_system
File Structure : 
src/               → top-level system
components/        → VGA subsystem (component + clock divider)
sync/              → VGA sync and timing generator
memory/            → true dual-port framebuffer RAM
test/              → test pattern generator (FSM)
