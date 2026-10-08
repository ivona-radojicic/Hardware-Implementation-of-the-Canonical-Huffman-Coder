transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+clk_wiz_0  -L xpm -L work -L unisims_ver -L unimacro_ver -L secureip -O5 work.clk_wiz_0 work.glbl

do {clk_wiz_0.udo}

run 1000ns

endsim

quit -force
