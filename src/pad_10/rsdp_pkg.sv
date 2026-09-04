package rsdp_pkg;

  localparam logic [6:0] FP = 7'b1111111;
  localparam logic [2:0] FZ = 3'b111;
  localparam int P_BIT_WIDTH = $clog2(FP);
  localparam int Z_BIT_WIDTH = $clog2(FZ);
  
//--------------------------------------------------------------------------
//RSDP-1-f
//  localparam int YV_SIZE = 20;
//  localparam int S_SIZE = 6;
//  localparam int V_SIZE = 6;
//  localparam int Y_SIZE = 14;
//  localparam int S_REM = 5;
//  localparam int V_REM = 0;
//  localparam int Y_REM = 0;
//  localparam int LEAVES[0:3] = '{40,39,39,39};
//  localparam int SECURITY_LVL = 1;
//  localparam int BUFF_SIZE_FZ = 11;
//  localparam int BUFF_FZ_PART = 6;
//  localparam int SIG_SIZE = 2304;
//  localparam logic [3:0] SHAKE_TYPE = 4'hC;
//  localparam int B_SIZE = 21;
//  localparam int LAMBDA = 128;
//  localparam int N_VEC = 127;
//  localparam int K_VEC =  76;
//  localparam int T_VEC = 157;
//  localparam int W_VEC =  82; 
//RSDP-1-b
//  localparam logic [3:0] SHAKE_TYPE = 4'hC;
//  localparam int LAMBDA = 128;
//  localparam int N_VEC = 127;
//  localparam int K_VEC =  76;
//  localparam int T_VEC = 256;
//  localparam int W_VEC = 215; 
//RSDP-1-s
//  localparam logic [3:0] SHAKE_TYPE = 4'hC;
//  localparam int LAMBDA = 128;
//  localparam int N_VEC = 127;
//  localparam int K_VEC =  76;
//  localparam int T_VEC = 520;
//  localparam int W_VEC = 488; 

//--------------------------------------------------------------------------
//RSDP-3-f
 localparam int YV_SIZE = 30;
 localparam int S_SIZE = 9;
 localparam int V_SIZE = 9;
 localparam int Y_SIZE = 21;
 localparam int S_REM = 3;
 localparam int V_REM = 7;
 localparam int Y_REM = 4;
 localparam int LEAVES[0:3] = '{60,60,60,59};
 localparam int SECURITY_LVL = 3;
 localparam int BUFF_SIZE_FZ = 16;
 localparam int BUFF_FZ_PART = 2;
 localparam int SIG_SIZE = 5176;
 localparam logic [3:0] SHAKE_TYPE = 4'hE;
 localparam int B_SIZE = 17;
 localparam int LAMBDA = 192;
 localparam int N_VEC = 187;
 localparam int K_VEC = 111;
 localparam int T_VEC = 239;
 localparam int W_VEC = 125; 
//RSDP-3-b
//  localparam logic [3:0] SHAKE_TYPE = 4'hE;
//  localparam int LAMBDA = 192;
//  localparam int N_VEC = 187;
//  localparam int K_VEC = 111;
//  localparam int T_VEC = 384;
//  localparam int W_VEC = 321; 
//RSDP-3-s
//  localparam logic [3:0] SHAKE_TYPE = 4'hE;
//  localparam int LAMBDA = 192;
//  localparam int N_VEC = 187;
//  localparam int K_VEC = 111;
//  localparam int T_VEC = 580;
//  localparam int W_VEC = 527; 

//--------------------------------------------------------------------------
//RSDP-5-f
// localparam int YV_SIZE = 40;
// localparam int S_SIZE = 12;
// localparam int V_SIZE = 12;
// localparam int Y_SIZE = 28;
// localparam int S_REM = 1;
// localparam int V_REM = 7;
// localparam int Y_REM = 4;
// localparam int LEAVES[0:3] = '{81,80,80,80};
// localparam int SECURITY_LVL = 5;
// localparam int BUFF_SIZE_FZ = 22;
// localparam int BUFF_FZ_PART = 5;
// localparam int SIG_SIZE = 9324;
// localparam logic [3:0] SHAKE_TYPE = 4'hE;
// localparam int B_SIZE = 17;
// localparam int LAMBDA = 256;
// localparam int N_VEC = 251;
// localparam int K_VEC = 150;
// localparam int T_VEC = 321;
// localparam int W_VEC = 167; 
//RSDP-5-b
//  localparam logic [3:0] SHAKE_TYPE = 4'hE;
//  localparam int LAMBDA = 256;
//  localparam int N_VEC = 251;
//  localparam int K_VEC = 150;
//  localparam int T_VEC = 512;
//  localparam int W_VEC = 427; 
//RSDP-5-s
//  localparam logic [3:0] SHAKE_TYPE = 4'hE;
//  localparam int LAMBDA = 256;
//  localparam int N_VEC = 251;
//  localparam int K_VEC = 150;
//  localparam int T_VEC = 832;
//  localparam int W_VEC = 762; 

localparam int LAMBDA_BLOCKS = LAMBDA/64;
localparam int C_VEC = 2*T_VEC - 1;
localparam logic [15:0] KGCONST = 3*T_VEC;
localparam logic [15:0] HASH_CONST = 32768;
  
endpackage