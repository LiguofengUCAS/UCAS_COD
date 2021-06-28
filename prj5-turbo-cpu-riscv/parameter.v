`define BR_WD              33

`define IF_TO_ID_DATA_WD   64
`define ID_TO_EXE_DATA_WD  194
`define EXE_TO_MEM_DATA_WD 111
`define MEM_TO_WB_DATA_WD  72
`define WB_TO_RF_DATA_WD   38

`define INST_RETIRE_WD     70

`define EXE_TO_ID_FW_WD    71
`define MEM_TO_ID_FW_WD    72
`define WB_TO_ID_FW_WD     70

//state
`define INIT               5'b00001

`define IF                 5'b00010
`define IW                 5'b00100
`define NPC                5'B01000

`define PRE                5'b00010
`define REQ                5'b00100
`define RDW                5'b01000
`define GO                 5'b10000

`define WAIT               5'b00010

`define YES_0              5'b00010
`define YES_1              5'b00100
`define NO_0               5'b01000
`define NO_1               5'b10000
