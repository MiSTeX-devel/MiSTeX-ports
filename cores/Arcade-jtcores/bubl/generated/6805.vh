reg jsr_en;
reg [11:0] jsr_ua, jsr_ret, uaddr;

// wire [3:0] alu_sel;
// wire [1:0] brt_sel;
// wire [3:0] cc_sel;
// wire [1:0] ea_sel;
// wire [4:0] jsr_sel;
// wire [2:0] ld_sel;
// wire [1:0] opnd_sel;
// wire [3:0] rmux_sel;

// wire       branch;
// wire       brlatch;
// wire       cin_carry;
// wire       halt;
// wire       fetch;
// wire       ni;
// wire       op0inv;
// wire       inc_pc;
// wire       wr;
// wire       stop;
// wire       md_shift;
// wire       swi;

reg  [37:0] ucode_rom[0:2**12-1];
wire [37:0] ucode_data;

initial begin
    $readmemb("6805.uc",ucode_rom);
end

assign ucode_data = ucode_rom[uaddr];

assign branch     = ucode_data[ 4+:1];
assign brlatch    = ucode_data[ 5+:1];
assign cin_carry  = ucode_data[ 8+:1];
assign halt       = ucode_data[15+:1];
assign fetch      = ucode_data[16+:1];
assign ni         = ucode_data[25+:1];
assign op0inv     = ucode_data[26+:1];
assign inc_pc     = ucode_data[29+:1];
assign wr         = ucode_data[34+:1];
assign stop       = ucode_data[35+:1];
assign md_shift   = ucode_data[36+:1];
assign swi        = ucode_data[37+:1];
assign alu_sel    = ucode_data[ 0+:4];
assign brt_sel    = ucode_data[ 6+:2];
assign cc_sel     = ucode_data[ 9+:4];
assign ea_sel     = ucode_data[13+:2];
assign jsr_sel    = ucode_data[17+:5];
assign ld_sel     = ucode_data[22+:3];
assign opnd_sel   = ucode_data[27+:2];
assign rmux_sel   = ucode_data[30+:4];


always @* begin
    case( jsr_sel )
        IVRD_JSR:    begin jsr_en=1; jsr_ua = 12'h82*12'd16; end 
        IMM_JSR:     begin jsr_en=1; jsr_ua = 12'h90*12'd16; end 
        DIR_JSR:     begin jsr_en=1; jsr_ua = 12'h91*12'd16; end 
        DIRA_JSR:    begin jsr_en=1; jsr_ua = 12'h87*12'd16; end 
        EXT_JSR:     begin jsr_en=1; jsr_ua = 12'h92*12'd16; end 
        EXTA_JSR:    begin jsr_en=1; jsr_ua = 12'h84*12'd16; end 
        IDX_JSR:     begin jsr_en=1; jsr_ua = 12'h93*12'd16; end 
        IDX8_JSR:    begin jsr_en=1; jsr_ua = 12'h94*12'd16; end 
        IDX8A_JSR:   begin jsr_en=1; jsr_ua = 12'h85*12'd16; end 
        IDX16_JSR:   begin jsr_en=1; jsr_ua = 12'h95*12'd16; end 
        IDX16A_JSR:  begin jsr_en=1; jsr_ua = 12'h96*12'd16; end 
        PSH8_JSR:    begin jsr_en=1; jsr_ua = 12'h3B*12'd16; end 
        PSH16_JSR:   begin jsr_en=1; jsr_ua = 12'h4B*12'd16; end 
        IDLE6_JSR:   begin jsr_en=1; jsr_ua = 12'hAF*12'd16; end 
        RTI8_JSR:    begin jsr_en=1; jsr_ua = 12'h7B*12'd16; end 
        RET_JSR:     begin jsr_en=1; jsr_ua = jsr_ret; end
        default:     begin jsr_en=0; jsr_ua = 'h00; end
    endcase
end
