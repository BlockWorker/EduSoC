# EduSoC
Minimalistic SoC framework for the Digilent Arty S7 FPGA board, intended for educational development of a RISC-V core.

Developed for the Institute of Computer Architecture and Computer Engineering at the University of Stuttgart.

A datasheet is available in the "doc" folder.

All SoC code is in the "soc" folder (aside from the IP configuration file in the "edusoc_system.srcs" folder).
Also provided are tools for programming the SoC over UART, testbenches, and a Vivado project creation script showing an example SoC configuration without a core.

In the "example" folder, a simple example RISC-V core is provided, along with a Vivado project creation script for showing its use, and some example programs for it.

Licensed under CERN-OHL-W-2.0.