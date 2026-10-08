vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/work
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap work questa_lib/msim/work
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -incr -mfcu  -sv "+incdir+../../../ipstatic" \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm  -93  \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work work  -incr -mfcu  "+incdir+../../../ipstatic" \
"../../../../diplomski_rad_ivona_radojicic.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../diplomski_rad_ivona_radojicic.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work work \
"glbl.v"

