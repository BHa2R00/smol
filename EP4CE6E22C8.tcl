set top top
load_package flow
project_new "${top}" -overwrite
set_global_assignment -name TOP_LEVEL_ENTITY $top
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE6E22C8
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY ./quartus_output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name AUTO_RAM_RECOGNITION ON
set_global_assignment -name VERILOG_FILE ./236.sv
set_location_assignment PIN_91  -to clk
set_location_assignment PIN_88  -to rstb
set_location_assignment PIN_11  -to io[0]
set_location_assignment PIN_84  -to io[1]
set_location_assignment PIN_80  -to io[2]
set_location_assignment PIN_76  -to io[3]
set_location_assignment PIN_10  -to io[4]
set_location_assignment PIN_72  -to io[5]
set_location_assignment PIN_70  -to io[6]
set_location_assignment PIN_68  -to io[7]
set_location_assignment PIN_98  -to halt
set_global_assignment -name SDC_FILE EP4CE6E22C8.sdc
execute_flow -compile
export_assignments
project_close
