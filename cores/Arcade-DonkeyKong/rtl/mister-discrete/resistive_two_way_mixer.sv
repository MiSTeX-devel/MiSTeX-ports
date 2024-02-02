/********************************************************************************\
 *
 *  MiSTer Discrete resistive two way mixer
 *
 *  Copyright 2022 by Jegor van Opdorp.
 *  This program is free software under the terms of the GPLv3, see LICENCSE.txt
 *
 *   inputs[0]    inputs[1]
 *        V         V
 *        |         |
 *        |         |
 *        Z         Z
 *     R0 Z         Z R1
 *        Z         Z
 *        |         |
 *        '----,----'
 *             |
 *             |
 *             V
 *            out
 *
 * This assumes that input 0 and 1 are driven by voltage outputs with
 * low enough output inpedance, and out drives a voltage input with high enough
 * input inpedance. (high and low enough compared to R0 and R1 at all
 * relveant frequencies)
 *
 ********************************************************************************/
module resistive_two_way_mixer #(
    parameter longint R0 = 10000,
    parameter longint R1 = 10000
) (
    input clk,
    input I_RSTn,
    input audio_clk_en,
    input signed[15:0] inputs[1:0],
    output reg[15:0] out = 0
);
    // r0:       65536, r1:       65536, norm:                 32768
    localparam integer R0_RATIO_16_SHIFTED = 32'((R1 <<< 16) / R0);
    localparam integer R1_RATIO_16_SHIFTED = 32'((R0 <<< 16) / R1);
    localparam longint NORMALIZATION_RATIO_16_SHIFTED = (1 <<< 32)/(R0_RATIO_16_SHIFTED+R1_RATIO_16_SHIFTED);

    always@(posedge clk, negedge I_RSTn) begin
        if(!I_RSTn)begin
            out <= 0;
        end else if(audio_clk_en)begin
            out <= 16'((R0_RATIO_16_SHIFTED * inputs[0] + R1_RATIO_16_SHIFTED * inputs[1]) * NORMALIZATION_RATIO_16_SHIFTED >>> 32);
        end
    end
endmodule