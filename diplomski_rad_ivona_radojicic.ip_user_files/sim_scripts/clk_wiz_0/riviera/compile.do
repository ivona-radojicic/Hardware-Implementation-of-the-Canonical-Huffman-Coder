transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/work
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap work riviera/work
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../ipstatic" -l xpm -l work \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"C:/Xilinx/Vivado/2024.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work work  -incr -v2k5 "+incdir+../../../ipstatic" -l xpm -l work \
"../../../../diplomski_rad_ivona_radojicic.gen/sources_1/ip/clk_wiz_0/clk_wiz_0_clk_wiz.v" \
"../../../../diplomski_rad_ivona_radojicic.gen/sources_1/ip/clk_wiz_0/clk_wiz_0.v" \

vlog -work work \
"glbl.v"

