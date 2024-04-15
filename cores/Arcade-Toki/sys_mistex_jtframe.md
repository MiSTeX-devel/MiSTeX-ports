#### 1. differences sys mister template / <u>sys jtframe</u>

vaig seguint l'ordre del sys jtframe que és el que vaig modificant per fer-lo compatible amb MiSTeX

* jtframe has pll/pll_0002.v
* pll_hdmi_0002.v mistex has commented out `//.mimic_fbclk_type("none"),`



#### 2. differences sys mister template / sys mistex

veure les diferències aquí primer i després aplicar els canvis a sys jtframe



## ERRORS

 [pll_cfg_hdmi.v](upstream/modules/jtframe/target/mister/sys/pll_cfg_hdmi.v) 





`ifdef CYCLONEV

`else

`endif

`ifndef MISTER_DEBUG_NOHDMI

`ifdef SKIP_ASCAL

`ifdef ALTERA





  FORCED_SCANDOUBLER=0
  VGA_SCALER=0
  VSYNC_ADJUST=0
  DVI_MODE=2
  FB_TERMINAL=1





Warning (12161): Node "sys_top:sys_top|VGA_HS" is stuck at GND because node is in wire loop and does not have a source

Warning (12161): Node "sys_top:sys_top|HDMI_I2C_SDA" is stuck at GND because node is in wire loop and does not have a source

CONNECTIVITY CHECKS





Warning (15714): Some pins have incomplete I/O assignments. Refer to the I/O Assignment Warnings report for details

Warning (171167): Found invalid Fitter assignments. See the Ignored Assignments panel in the Fitter Compilation Report for more information.



```sh
Found dir: games/mame
mame_root games
Using interleave: input 8, output 16
        file: games/mame/toki.zip/6e.m10, start=0, len=0, map(2)=10
     0: file: games/mame/toki.zip/4e.k10, start=0, len=0, map(2)=1
Disable interleave
Using interleave: input 8, output 16
        file: games/mame/toki.zip/5.m12, start=0, len=0, map(2)=10
 40000: file: games/mame/toki.zip/3.k12, start=0, len=0, map(2)=1
Disable interleave
 60000: file: games/mame/toki.zip/1.c5, start=0, len=0
 70000: file: games/mame/toki.zip/2.c3, start=0, len=0
 80000: file: games/mame/toki.zip/toki_obj1.c20, start=0, len=0
100000: file: games/mame/toki.zip/toki_obj2.c22, start=0, len=0
180000: file: games/mame/toki.zip/toki_bk1.cd8, start=0, len=0
200000: file: games/mame/toki.zip/toki_bk2.ef8, start=0, len=0
280000: file: games/mame/toki.zip/8.m3, start=0, len=0
282000: file: games/mame/toki.zip/7.m7, start=0, len=0
292000: file: games/mame/toki.zip/9.m1, start=0, len=0
file_finish: 0x2B2000 bytes sent to FPGA

FileOpen(��x���, config/dips/Toki (World, set 1).dip, )
FileOpen(Toki (World, set 1).dip, config/cheats/Toki (World, set 1).dip, )
FileOpenEx(open) File:/media/fat/config/cheats/Toki (World, set 1).dip, error: No such file or directory.
sh: 1: uartmode: not found
sh: 1: uartmode: not found
user_io_init done!
Open up to 30 input devices.
make_unique(289B,0057,-1)
make_unique(0E8F,3013,1)
make_unique(16C0,05E1,1)
make_unique(045E,02A1,1)
make_unique(8282,3201,1)
make_unique(1209,FACA,1)
opened 0( 0): /dev/input/event5 (0001:0001) 0 "sunxi-ir/input0" "sunxi-ir"
opened 1( 1): /dev/input/event4 (0079:0011) 0 "usb-5200000.usb-1.1/input0/GH-SP-5027-1 H2" "SWITCH CO.,LTD. USB Gamepad "
opened 2( 2): /dev/input/event3 (046d:4016) 0 "usb-5200000.usb-1.4/input2:2/3a-2e-29-8f" "Logitech K330"
opened 3( 3): /dev/input/event2 (046d:401b) 0 "usb-5200000.usb-1.4/input2:1/38-f4-af-7c" "Logitech M215 2nd Gen"
opened 4( 3): /dev/input/mouse0 (046d:401b) 0 "usb-5200000.usb-1.4/input2:1/38-f4-af-7c" "Logitech M215 2nd Gen"
opened 5( 5): /dev/input/event1 (0001:0001) 0 "sun4i_lradc/input0" "5070800.lradc"
opened 6( 6): /dev/input/event0 (0000:0000) 0 "m1kbd/input2" "axp20x-pek"
FileOpen(��x���, config/inputs/input_046d_4016_v3.map, )
FileOpenEx(open) File:/media/fat/config/inputs/input_046d_4016_v3.map, error: No such file or directory.
FileOpen(input_046d_4016_v3.map, config/input_046d_4016_v3.map, )
FileOpenEx(open) File:/media/fat/config/input_046d_4016_v3.map, error: No such file or directory.
FileOpen(, /media/fat/linux/gamecontrollerdb/gamecontrollerdb_user.txt, )
FileOpenEx(open) File:/media/fat/linux/gamecontrollerdb/gamecontrollerdb_user.txt, error: No such file or directory.
FileOpen(gamecontrollerdb_user.txt, /media/fat/linux/gamecontrollerdb/gamecontrollerdb.txt, )
Gamecontrollerdb: searching for GUID 030000006d0400001640000011010000 in file /media/fat/linux/gamecontrollerdb/gamecontrollerdb.txt
FileOpen(��x���, config/inputs/Toki_input_046d_4016_v3.map, )
FileOpen(��x���, config/kbd_046d_4016.map, )
FileOpenEx(open) File:/media/fat/config/kbd_046d_4016.map, error: No such file or directory.
user_io_read_confstr, got: 'TOKI;;DIP;P1,Video;P1oLO,CRT H offset,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;P1oPS,CRT V offset,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;P1oG,CRT scale enable,Off,On;H2P1oHK,CRT scale factor,0,+1,+2,+3,+4,+5,+6,+7,-8,-7,-6,-5,-4,-3,-2,-1;P1-;d3P1O35,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;H0P1OGH,Aspect ratio,Original,Full screen,[ARC1],[ARC2];d5P1o9,Vertical Crop,Disabled,216p(5x);d5P1oAD,Crop Offset,0,2,4,8,10,12,-12,-10,-8,-6,-4,-2;P1oEF,Scale,Normal,V-Integer,Narrower HV-Integer,Wider HV-Integer;-;O67,FX volume,high,highest,lowest,low;O8,FX,On,Off;O9,FM,On,Off;o5,User port,Off,DB15 Joystick;OC,Show credits in pause,On,Off;R0,Reset;V,v57052818'

```



## TODO

* TCL fitxers amb locations de la GX150

  

### TODO XILINX

* sys/pll/pll_0002.v
* sys_top.xdc  (add jtframe lines from sys_top.sdc)



##### Canvis

* hq2x.sv

  * ```
    `ifdef XILINX
    (* romstyle = "logic" *) reg [5:0] hqTable[256];
    `else
    (* romstyle = "MLAB" *) reg [5:0] hqTable[256];
    `endif
    ```


* scandoubler.v

```
module scandoubler #(parameter LENGTH=768, parameter HALF_DEPTH=0)
```

