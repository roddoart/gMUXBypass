create_clock -add -period 30.000 \
-waveform { 0.000 15.000 } \
-name clock_name \
[get_ports LPC_CLK33M_GMUX]