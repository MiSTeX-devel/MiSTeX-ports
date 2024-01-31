#============================================================
# SDIO
#============================================================
# set_location_assignment PIN_ -to SDIO_DAT[0]
# set_location_assignment PIN_ -to SDIO_DAT[1]
# set_location_assignment PIN_ -to SDIO_DAT[2]
# set_location_assignment PIN_ -to SDIO_DAT[3]
# set_location_assignment PIN_ -to SDIO_CMD
# set_location_assignment PIN_ -to SDIO_CLK
# set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDIO_*
# 
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDIO_*
# set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_DAT[*]
# set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDIO_CMD

#============================================================
# VGA
#============================================================
set_location_assignment PIN_K22 -to VGA_R[5]
set_location_assignment PIN_K17 -to VGA_R[4]
set_location_assignment PIN_M16 -to VGA_R[3]
set_location_assignment PIN_K21 -to VGA_R[2]
set_location_assignment PIN_N16 -to VGA_R[1]
set_location_assignment PIN_L18 -to VGA_G[5]
set_location_assignment PIN_N19 -to VGA_G[4]
set_location_assignment PIN_M22 -to VGA_G[3]
set_location_assignment PIN_L19 -to VGA_G[2]
set_location_assignment PIN_L22 -to VGA_G[1]
set_location_assignment PIN_L17 -to VGA_G[0]
set_location_assignment PIN_N21 -to VGA_B[5]
set_location_assignment PIN_N20 -to VGA_B[4]
set_location_assignment PIN_M20 -to VGA_B[3]
set_location_assignment PIN_M21 -to VGA_B[2]
set_location_assignment PIN_M18 -to VGA_B[1]
set_location_assignment PIN_P17 -to VGA_HS
set_location_assignment PIN_P16 -to VGA_VS
# set_location_assignment PIN_ -to VGA_EN
#set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to VGA_EN

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_*
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_*

#============================================================
# AUDIO
#============================================================
# J11 pins 1 2 3
set_location_assignment PIN_G1 -to AUDIO_L
set_location_assignment PIN_E2 -to AUDIO_R
set_location_assignment PIN_C1 -to AUDIO_SPDIF
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUDIO_*
set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to AUDIO_*

#============================================================
# I/O #1
#============================================================
set_location_assignment PIN_A10 -to LED_USER
set_location_assignment PIN_A9 -to LED_HDD
set_location_assignment PIN_A8 -to LED_POWER

# set_location_assignment PIN_ -to BTN_USER
set_location_assignment PIN_AB13 -to BTN_OSD
set_location_assignment PIN_V18  -to BTN_RESET

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED_*
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to BTN_*
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to BTN_*
