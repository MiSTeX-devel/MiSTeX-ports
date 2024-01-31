set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CEFA2F23C8

#============================================================
# SDIO_CD or SPDIF_OUT
#============================================================
set_location_assignment PIN_G6 -to SDCD_SPDIF
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDCD_SPDIF
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDCD_SPDIF
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDCD_SPDIF

#============================================================
# SDRAM
#============================================================
set_location_assignment PIN_P8 -to SDRAM_A[0]
set_location_assignment PIN_P7 -to SDRAM_A[1]
set_location_assignment PIN_N8 -to SDRAM_A[2]
set_location_assignment PIN_N6 -to SDRAM_A[3]
set_location_assignment PIN_U6 -to SDRAM_A[4]
set_location_assignment PIN_U7 -to SDRAM_A[5]
set_location_assignment PIN_V6 -to SDRAM_A[6]
set_location_assignment PIN_U8 -to SDRAM_A[7]
set_location_assignment PIN_T8 -to SDRAM_A[8]
set_location_assignment PIN_W8 -to SDRAM_A[9]
set_location_assignment PIN_R6 -to SDRAM_A[10]
set_location_assignment PIN_T9 -to SDRAM_A[11]
set_location_assignment PIN_Y9 -to SDRAM_A[12]
set_location_assignment PIN_T7 -to SDRAM_BA[0]
set_location_assignment PIN_P9 -to SDRAM_BA[1]
set_location_assignment PIN_AA12 -to SDRAM_DQ[0]
set_location_assignment PIN_Y11  -to SDRAM_DQ[1]
set_location_assignment PIN_AA10 -to SDRAM_DQ[2]
set_location_assignment PIN_AB10 -to SDRAM_DQ[3]
set_location_assignment PIN_Y10  -to SDRAM_DQ[4]
set_location_assignment PIN_AA9  -to SDRAM_DQ[5]
set_location_assignment PIN_AB8  -to SDRAM_DQ[6]
set_location_assignment PIN_AA8  -to SDRAM_DQ[7]
set_location_assignment PIN_U10  -to SDRAM_DQ[8]
set_location_assignment PIN_T10  -to SDRAM_DQ[9]
set_location_assignment PIN_U11  -to SDRAM_DQ[10]
set_location_assignment PIN_R12  -to SDRAM_DQ[11]
set_location_assignment PIN_U12  -to SDRAM_DQ[12]
set_location_assignment PIN_P12  -to SDRAM_DQ[13]
set_location_assignment PIN_R10  -to SDRAM_DQ[14]
set_location_assignment PIN_R11  -to SDRAM_DQ[15]
set_location_assignment PIN_AB7  -to SDRAM_DQML
set_location_assignment PIN_V10  -to SDRAM_DQMH
set_location_assignment PIN_AB11 -to SDRAM_CLK
set_location_assignment PIN_V9 -to SDRAM_CKE
set_location_assignment PIN_W9 -to SDRAM_nWE
set_location_assignment PIN_AA7 -to SDRAM_nCAS
set_location_assignment PIN_AB5 -to SDRAM_nCS
set_location_assignment PIN_AB6 -to SDRAM_nRAS

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM_*
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM_*
set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM_DQ[*]
set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM_*

#============================================================
# SPI SD
#============================================================
set_location_assignment PIN_AA13 -to SD_SPI_CS
set_location_assignment PIN_AB15  -to SD_SPI_MISO
set_location_assignment PIN_Y15  -to SD_SPI_CLK
set_location_assignment PIN_Y14  -to SD_SPI_MOSI
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SD_SPI*
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SD_SPI*
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SD_SPI*


#============================================================
# HPS SPI
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to HPS_*

# pmodb pins 1-4
set_location_assignment PIN_AA2 -to HPS_SPI_MOSI
set_location_assignment PIN_Y3  -to HPS_SPI_MISO
set_location_assignment PIN_U1  -to HPS_SPI_CLK
set_location_assignment PIN_N1  -to HPS_SPI_CS

set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to HPS_SPI_CLK

# pmodb pins 5-7
set_location_assignment PIN_AA1 -to HPS_FPGA_ENABLE
set_location_assignment PIN_W2  -to HPS_OSD_ENABLE
set_location_assignment PIN_U2  -to HPS_IO_ENABLE

# DEBUG
set_location_assignment PIN_C11 -to DEBUG[0]
set_location_assignment PIN_B12 -to DEBUG[1]
set_location_assignment PIN_E12 -to DEBUG[2]
set_location_assignment PIN_D13 -to DEBUG[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to DEBUG[*]

#============================================================
# CLOCK
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLK_50
set_location_assignment PIN_M9 -to CLK_50

#============================================================
# LED
#============================================================
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to LED[7]
set_location_assignment PIN_E9 -to LED[0]
set_location_assignment PIN_H8 -to LED[1]
set_location_assignment PIN_E7 -to LED[2]
set_location_assignment PIN_D9 -to LED[3]
set_location_assignment PIN_A5 -to LED[4]
set_location_assignment PIN_D6 -to LED[5]
set_location_assignment PIN_G8 -to LED[6]
set_location_assignment PIN_C6 -to LED[7]

# TODO spi
# TODO uart
# TODO hdmi_i2c

set_global_assignment -name PRE_FLOW_SCRIPT_FILE "quartus_sh:sys/build_id.tcl"

set_global_assignment -name CDF_FILE jtag.cdf
set_global_assignment -name QIP_FILE sys/sys.qip

set_global_assignment -name VERILOG_MACRO "MISTER_DEBUG_NOHDMI=1"
