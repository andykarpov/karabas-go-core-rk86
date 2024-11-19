

 
 
 




window new WaveWindow  -name  "Waves for BMG Example Design"
waveform  using  "Waves for BMG Example Design"

      waveform add -signals /rambuffer_tb/status
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/CLKA
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/ADDRA
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/DINA
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/WEA
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/DOUTA
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/CLKB
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/ADDRB
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/DINB
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/WEB
      waveform add -signals /rambuffer_tb/rambuffer_synth_inst/bmg_port/DOUTB

console submit -using simulator -wait no "run"
