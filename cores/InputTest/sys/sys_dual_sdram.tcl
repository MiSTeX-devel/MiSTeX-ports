#============================================================
# Secondary SDRAM
#============================================================
set_location_assignment PIN_  -to SDRAM2_DQ[0]
set_location_assignment PIN_ -to SDRAM2_DQ[1]
set_location_assignment PIN_ -to SDRAM2_DQ[2]
set_location_assignment PIN_ -to SDRAM2_DQ[3]
set_location_assignment PIN_ -to SDRAM2_DQ[4]
set_location_assignment PIN_ -to SDRAM2_DQ[5]
set_location_assignment PIN_ -to SDRAM2_DQ[6]
set_location_assignment PIN_ -to SDRAM2_DQ[7]
set_location_assignment PIN_ -to SDRAM2_DQ[14]
set_location_assignment PIN_ -to SDRAM2_DQ[15]

set_location_assignment PIN_ -to SDRAM2_DQ[13]
set_location_assignment PIN_ -to SDRAM2_DQ[12]
set_location_assignment PIN_ -to SDRAM2_DQ[11]
set_location_assignment PIN_ -to SDRAM2_DQ[10]
set_location_assignment PIN_ -to SDRAM2_DQ[9]
set_location_assignment PIN_ -to SDRAM2_DQ[8]
set_location_assignment PIN_ -to SDRAM2_A[12]
set_location_assignment PIN_ -to SDRAM2_CLK
set_location_assignment PIN_ -to SDRAM2_A[9]
set_location_assignment PIN_ -to SDRAM2_A[11]
set_location_assignment PIN_ -to SDRAM2_A[7]
set_location_assignment PIN_ -to SDRAM2_A[8]
set_location_assignment PIN_ -to SDRAM2_A[5]
set_location_assignment PIN_ -to SDRAM2_A[6]
set_location_assignment PIN_ -to SDRAM2_nWE
set_location_assignment PIN_ -to SDRAM2_A[4]

set_location_assignment PIN_ -to SDRAM2_nCAS
set_location_assignment PIN_ -to SDRAM2_nRAS
set_location_assignment PIN_ -to SDRAM2_nCS
set_location_assignment PIN_ -to SDRAM2_BA[0]
set_location_assignment PIN_ -to SDRAM2_BA[1]
set_location_assignment PIN_ -to SDRAM2_A[10]
set_location_assignment PIN_ -to SDRAM2_A[0]
set_location_assignment PIN_ -to SDRAM2_A[1]
set_location_assignment PIN_ -to SDRAM2_A[2]
set_location_assignment PIN_ -to SDRAM2_A[3]

set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SDRAM2_*
set_instance_assignment -name CURRENT_STRENGTH_NEW "MAXIMUM CURRENT" -to SDRAM2_*
set_instance_assignment -name FAST_OUTPUT_REGISTER ON -to SDRAM2_*
set_instance_assignment -name FAST_OUTPUT_ENABLE_REGISTER ON -to SDRAM2_DQ[*]
set_instance_assignment -name FAST_INPUT_REGISTER ON -to SDRAM2_DQ[*]
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to SDRAM2_DQ[*]
set_instance_assignment -name ALLOW_SYNCH_CTRL_USAGE OFF -to *|SDRAM2_*

set_global_assignment -name VERILOG_MACRO "MISTER_DUAL_SDRAM=1"