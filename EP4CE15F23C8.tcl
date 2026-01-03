set top top
load_package flow
project_new "${top}" -overwrite
set_global_assignment -name TOP_LEVEL_ENTITY $top
set_global_assignment -name FAMILY "Cyclone IV E"
set_global_assignment -name DEVICE EP4CE15F23C8
set_global_assignment -name PROJECT_OUTPUT_DIRECTORY ./quartus_output_files
set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
set_global_assignment -name AUTO_RAM_RECOGNITION ON
set_global_assignment -name VERILOG_FILE ./hw.sv
set_location_assignment PIN_T22  -to clk
set_location_assignment PIN_U20  -to rstb
set_location_assignment PIN_U1   -to io[0]
set_location_assignment PIN_V1   -to io[1]
set_location_assignment PIN_F12  -to io[2]
set_location_assignment PIN_Y17  -to halt
set_location_assignment PIN_AA3  -to debug[0]
set_location_assignment PIN_AB3  -to debug[1]
set_location_assignment PIN_AB4  -to debug[2]
set_global_assignment -name SDC_FILE EP4CE15F23C8.sdc
execute_flow -compile
export_assignments
project_close
