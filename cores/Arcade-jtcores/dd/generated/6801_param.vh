/*  This file is part of JTCORES.
    JTCORES program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    JTCORES program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with JTCORES.  If not, see <http://www.gnu.org/licenses/>.

    Author: Jose Tejada Gomez. Twitter: @topapate
    Version: 1.0
    Date: 02-05-2024 */

// Control signals
localparam [3:0] // ALU
         ADD_ALU = 4'd1,
         AND_ALU = 4'd2,
         ASR_ALU = 4'd3,
         DAA_ALU = 4'd4,
         EOR_ALU = 4'd5,
         LSL_ALU = 4'd6,
         LSR_ALU = 4'd7,
         MUL_ALU = 4'd8,
          OR_ALU = 4'd9,
         SUB_ALU = 4'd10;

localparam [1:0] // CARRY
       CIN_CARRY = 2'd1,
       SHL_CARRY = 2'd2,
       SHR_CARRY = 2'd3;

localparam [4:0] // CC
            C_CC = 5'd1,
           C0_CC = 5'd2,
           C1_CC = 5'd3,
        HNZVC_CC = 5'd4,
           I0_CC = 5'd5,
           I1_CC = 5'd6,
     N0Z1V0C0_CC = 5'd7,
        N0ZVC_CC = 5'd8,
          NZV_CC = 5'd9,
         NZV0_CC = 5'd10,
       NZV0C0_CC = 5'd11,
       NZV0C1_CC = 5'd12,
         NZVC_CC = 5'd13,
           V0_CC = 5'd14,
           V1_CC = 5'd15,
            Z_CC = 5'd16;

localparam [1:0] // EA
            M_EA = 2'd1,
            S_EA = 2'd2;

localparam [4:0] // JSR
         DIR_JSR = 5'd1,
       DIR16_JSR = 5'd2,
        DIRA_JSR = 5'd3,
         EXT_JSR = 5'd4,
       EXT16_JSR = 5'd5,
        EXTA_JSR = 5'd6,
       IDLE4_JSR = 5'd7,
       IDLE6_JSR = 5'd8,
         IDX_JSR = 5'd9,
       IDX16_JSR = 5'd10,
        IDXA_JSR = 5'd11,
         IMM_JSR = 5'd12,
       IMM16_JSR = 5'd13,
        IVRD_JSR = 5'd14,
       PSH16_JSR = 5'd15,
        PSH8_JSR = 5'd16,
       PUL16_JSR = 5'd17,
        PUL8_JSR = 5'd18,
         RET_JSR = 5'd19,
        RTI8_JSR = 5'd20;

localparam [3:0] // LD
            A_LD = 4'd1,
            B_LD = 4'd2,
           CC_LD = 4'd3,
            D_LD = 4'd4,
           EA_LD = 4'd5,
           MD_LD = 4'd6,
           PC_LD = 4'd7,
            S_LD = 4'd8,
            X_LD = 4'd9;

localparam [1:0] // OPND
        LD0_OPND = 2'd1,
        LD1_OPND = 2'd2;

localparam [3:0] // RMUX
          A_RMUX = 4'd1,
          B_RMUX = 4'd2,
         CC_RMUX = 4'd3,
          D_RMUX = 4'd4,
         EA_RMUX = 4'd5,
         IV_RMUX = 4'd6,
         MD_RMUX = 4'd7,
        ONE_RMUX = 4'd8,
         PC_RMUX = 4'd9,
          S_RMUX = 4'd10,
          X_RMUX = 4'd11,
       ZERO_RMUX = 4'd12;

// entry points for ucode procedures
localparam DIR_SEQA             = 12'h140;
localparam DIR16_SEQA           = 12'h150;
localparam DIRA_SEQA            = 12'h450;
localparam EXT_SEQA             = 12'h1C0;
localparam EXT16_SEQA           = 12'h1D0;
localparam EXTA_SEQA            = 12'h550;
localparam IDLE4_SEQA           = 12'h870;
localparam IDLE6_SEQA           = 12'h420;
localparam IDX_SEQA             = 12'h1E0;
localparam IDX16_SEQA           = 12'h1F0;
localparam IDXA_SEQA            = 12'h4B0;
localparam IMM_SEQA             = 12'h120;
localparam IMM16_SEQA           = 12'h130;
localparam ISRV_SEQA            = 12'hC70;
localparam IVRD_SEQA            = 12'h0;
localparam PSH16_SEQA           = 12'h20;
localparam PSH8_SEQA            = 12'h4E0;
localparam PUL16_SEQA           = 12'h410;
localparam PUL8_SEQA            = 12'h30;
localparam RTI16_SEQA           = 12'h520;
localparam RTI8_SEQA            = 12'h510;