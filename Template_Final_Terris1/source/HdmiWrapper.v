module HdmiWrapper(
                                     // Chip ms72xx
   input             rstn          , // pll lock
   input             cfg_clk       , // 10Mhz
   output            iic_tx_scl    ,
   inout             iic_tx_sda    ,
   output            init_over     ,
   output            rstn_out      ,
                                     // HDMI output 
   input             pix_clk       , // 148.5Mhz                           
   output            vs_out        , 
   output            hs_out        , 
   output            de_out        ,
   output     [7:0]  r_out         , 
   output     [7:0]  g_out         , 
   output     [7:0]  b_out         ,
                                     // Game Pix output
   output     [4:0]  bitmap_row    ,
   input      [31:0] bitmap_data
);

parameter   X_WIDTH = 4'd12;
parameter   Y_WIDTH = 4'd12;  

//MODE_1080p
parameter V_TOTAL = 12'd1125;
parameter V_FP = 12'd4;
parameter V_BP = 12'd36;
parameter V_SYNC = 12'd5;
parameter V_ACT = 12'd1080;
parameter H_TOTAL = 12'd2200;
parameter H_FP = 12'd88;
parameter H_BP = 12'd148;
parameter H_SYNC = 12'd44;
parameter H_ACT = 12'd1920;
parameter HV_OFFSET = 12'd0;


reg  [15:0]                 rstn_1ms   ;
wire [X_WIDTH - 1'b1:0]     act_x      ;
wire [Y_WIDTH - 1'b1:0]     act_y      ;    
wire                        hs         ;
wire                        vs         ;
wire                        de         ;
reg  [3:0]                  reset_delay_cnt;


// bitmap mapping to act_y (0 ~ V_ACT / 1080)
//                to act_x (0 ~ H_ACT / 1920)
// bitmap has 32 x 16 blocks
//        block size in HDMI pix: 32 x 32 --> 1024 x 512
localparam BITMAP_Y_OFFSET = 12'd28;    // (1080 - 32 X 32) / 2
localparam BITMAP_Y_MAX    = 12'd1052;  // V_ACT - BITMAP_Y_OFFSET
localparam BITMAP_X_OFFSET = 12'd704;   // (1920 - 16 X 32) / 2
localparam BITMAP_X_MAX    = 12'd1216;  // H_ACT - BITMAP_X_OFFSET

reg [4:0] bitmap_row_r;
reg [3:0] bitmap_col_r;
reg [1:0] pix_data;

wire [X_WIDTH - 1'b1:0] act_x_woffset = act_x - BITMAP_X_OFFSET;
wire [Y_WIDTH - 1'b1:0] act_y_woffset = act_y - BITMAP_Y_OFFSET;

assign bitmap_row = bitmap_row_r;

always @(*) begin
    if (act_y < BITMAP_Y_OFFSET) begin
        bitmap_row_r = 5'd0;
    end 
    else if (act_y >= BITMAP_Y_MAX) begin 
        bitmap_row_r = 5'd0;
    end
    else begin
        bitmap_row_r = act_y_woffset >> 5;
    end 
end 

always @(*) begin
    if (act_x < BITMAP_X_OFFSET) begin
        bitmap_col_r = 5'd0;
    end 
    else if (act_x >= BITMAP_X_MAX) begin 
        bitmap_col_r = 5'd0;
    end
    else begin
        bitmap_col_r = act_x_woffset >> 5;
    end 
end 

localparam BITMAP_DATA_BLACK = 2'b11;

always @(*) begin
    if (act_y < BITMAP_Y_OFFSET) begin
        pix_data = BITMAP_DATA_BLACK;
    end 
    else if (act_y >= BITMAP_Y_MAX) begin 
        pix_data = BITMAP_DATA_BLACK;
    end 
    else if (act_x < BITMAP_X_OFFSET) begin
        pix_data = BITMAP_DATA_BLACK;
    end 
    else if (act_x >= BITMAP_X_MAX) begin 
        pix_data = BITMAP_DATA_BLACK;
    end
    else if (act_x_woffset[4:0] == 5'd0) begin
        pix_data = BITMAP_DATA_BLACK;
    end 
    else if (act_y_woffset[4:0] == 5'd0) begin
        pix_data = BITMAP_DATA_BLACK;
    end
    else begin
        case (bitmap_col_r)
            4'd0: pix_data = {bitmap_data[16], bitmap_data[0]};
            4'd1: pix_data = {bitmap_data[17], bitmap_data[1]};
            4'd2: pix_data = {bitmap_data[18], bitmap_data[2]};
            4'd3: pix_data = {bitmap_data[19], bitmap_data[3]};
            4'd4: pix_data = {bitmap_data[20], bitmap_data[4]};
            4'd5: pix_data = {bitmap_data[21], bitmap_data[5]};
            4'd6: pix_data = {bitmap_data[22], bitmap_data[6]};
            4'd7: pix_data = {bitmap_data[23], bitmap_data[7]};
            4'd8: pix_data = {bitmap_data[24], bitmap_data[8]};
            4'd9: pix_data = {bitmap_data[25], bitmap_data[9]};
            4'd10: pix_data = {bitmap_data[26], bitmap_data[10]};
            4'd11: pix_data = {bitmap_data[27], bitmap_data[11]};
            4'd12: pix_data = {bitmap_data[28], bitmap_data[12]};
            4'd13: pix_data = {bitmap_data[29], bitmap_data[13]};
            4'd14: pix_data = {bitmap_data[30], bitmap_data[14]};
            4'd15: pix_data = {bitmap_data[31], bitmap_data[15]};
        endcase
    end 
end 


ms72xx_ctl ms72xx_ctl(
    .clk         (  cfg_clk    ), //input       clk,
    .rst_n       (  rstn_out   ), //input       rstn,      
    .init_over   (  init_over  ), //output      init_over,
    .iic_tx_scl  (  iic_tx_scl ), //output      iic_scl,
    .iic_tx_sda  (  iic_tx_sda ), //inout       iic_sda
    .iic_scl     (  iic_scl    ), //output      iic_scl,
    .iic_sda     (  iic_sda    )  //inout       iic_sda
);

always @(posedge cfg_clk)
begin
	if(!rstn)
	    rstn_1ms <= 16'd0;
	else
	begin
		if(rstn_1ms == 16'h2710)
		    rstn_1ms <= rstn_1ms;
		else
		    rstn_1ms <= rstn_1ms + 1'b1;
	end
end
    
assign rstn_out = (rstn_1ms == 16'h2710);

sync_vg #(
    .X_BITS               (  X_WIDTH              ), 
    .Y_BITS               (  Y_WIDTH              ),
    .V_TOTAL              (  V_TOTAL              ),//                        
    .V_FP                 (  V_FP                 ),//                        
    .V_BP                 (  V_BP                 ),//                        
    .V_SYNC               (  V_SYNC               ),//                        
    .V_ACT                (  V_ACT                ),//                        
    .H_TOTAL              (  H_TOTAL              ),//                        
    .H_FP                 (  H_FP                 ),//                        
    .H_BP                 (  H_BP                 ),//                        
    .H_SYNC               (  H_SYNC               ),//                        
    .H_ACT                (  H_ACT                ) //                        

) sync_vg                                         
(                                                 
    .clk                  (  pix_clk              ),//input                   clk,                                 
    .rstn                 (  rstn_out             ),//input                   rstn,                            
    .vs_out               (  vs                   ),//output reg              vs_out,                                                                                                                                      
    .hs_out               (  hs                   ),//output reg              hs_out,            
    .de_out               (  de                   ),//output reg              de_out,             
    .x_act                (  act_x                ),//output reg [X_BITS-1:0] x_out,             
    .y_act                (  act_y                ) //output reg [Y_BITS:0]   y_out,             
);

pattern_vg #(
    .COCLOR_DEPP          (  8                    ), // Bits per channel
    .H_ACT                (  H_ACT                ),
    .V_ACT                (  V_ACT                )
) // Number of fractional bits for ramp pattern
pattern_vg (
    .rstn                 (  rstn_out             ),//input                         rstn,                                                     
    .pix_clk              (  pix_clk              ),//input                         clk_in,   
    .pix_data             (  pix_data             ),//input                         pix_data,
    // input video timing
    .vs_in                (  vs                   ),//input                         vn_in                        
    .hs_in                (  hs                   ),//input                         hn_in,                           
    .de_in                (  de                   ),//input                         dn_in,
    // test pattern image output                                                    
    .vs_out               (  vs_out               ),//output reg                    vn_out,                       
    .hs_out               (  hs_out               ),//output reg                    hn_out,                       
    .de_out               (  de_out               ),//output reg                    den_out,                      
    .r_out                (  r_out                ),//output reg [COCLOR_DEPP-1:0]  r_out,                      
    .g_out                (  g_out                ),//output reg [COCLOR_DEPP-1:0]  g_out,                       
    .b_out                (  b_out                ) //output reg [COCLOR_DEPP-1:0]  b_out   
);


endmodule