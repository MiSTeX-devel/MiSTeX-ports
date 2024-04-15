`timescale 1ns/1ps

module test;

reg  clk, cen=0, ss=0;
wire cen_sr,  cen_sr4, cen_sr4b, cen_sr32;
integer cnt=0;
real cnt_ss=0, cnt_no=0, t1;

initial begin
    $dumpfile("test.lxt");
    $dumpvars;
    clk=0;
    forever #(473.48/2) clk=~clk;
end

always @(posedge clk) begin
    cen <= ~cen;
    cnt <= cnt+1;
    if( cen_sr ) begin
        if(ss)
            cnt_ss <= cnt_ss+1;
        else
            cnt_no <= cnt_no+1;
    end
    if(cnt==10000) begin
        ss=1;
        t1=$time;
    end
    if(cnt==20000) begin
        $display("cen     = %.0f (expected 1.056Mhz)",20000*1e9/$time/2);
        $display("ss low  = %.0f (expected 6.5kHz)",cnt_no*1e9/t1);
        $display("ss high = %.0f (expected 8  kHz)",cnt_ss*1e9/($time-t1));
        $finish;
    end
end

jt6295_timing uut(
    .clk        ( clk       ),
    .cen        ( cen       ),
    .ss         ( ss        ),
    .cen_sr     ( cen_sr    ),   // Sample rate
    .cen_sr4    ( cen_sr4   ),  // 4x sample rate
    .cen_sr4b   ( cen_sr4b  ), // 4x sample rate, 180 shift
    .cen_sr32   ( cen_sr32  )
);

endmodule