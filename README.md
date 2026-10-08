# Hardware Implementation of the Canonical Huffman Coder

## Overview
This project implements an end-to-end Canonical Huffman Coder in VHDL for FPGA hardware acceleration. It dynamically constructs Huffman trees and compresses/decompresses ASCII data streams with bit-exact accuracy.

## Features
- **Language:** VHDL, Python
- **Tools:** Xilinx Vivado
- **Interface:** UART communication
- **Verification:** Custom Python testbench

## Architecture
- **Sorting module:** Hardware module for sorting symbol frequencies in one cycle.
- **Creating the Tree:** Using two queues to avoid repeatedly sorting the list after each new node is created, since the internal nodes are generated in ascending order of their frequencies.
- **Canonical Prefix Encoder:** Generates canonical codes.
- **UART Interface:** Bridges FPGA hardware with PC software.
