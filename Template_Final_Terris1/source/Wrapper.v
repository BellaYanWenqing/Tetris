module Wrapper #(
   parameter AREA_ROW = 32,
   parameter AREA_COL = 16,
   parameter ROW_ADDR_W = 5,
   parameter COL_ADDR_W = 4,
   parameter SPEED_FREQ = 50_000_000
) (
   input                            clk,
   input                            rstn,
   input                            pressed_left,  // key event
   input                            pressed_right, //
   input                            pressed_up,    //
   input                            pressed_down,  //
   input                            pressed_speed_up_down, 
   input                            pressed_pause_or_start,
   input    [ROW_ADDR_W-1:0]        r1_row,        // output channel #1
   output   [AREA_COL*2-1:0]        r1_data,       //         : data
   input    [ROW_ADDR_W-1:0]        r2_row,        // output channel #1
   output   [AREA_COL*2-1:0]        r2_data,       //         : data
   output                           falling_update,// block falling update signal, indicate speed
   output                           game_over,
   output   [9:0]                   game_score
);


//==========================================================================
// wire and reg in the module
//==========================================================================

wire    [ROW_ADDR_W-1:0]        cur_blk_row;    // current moving block
wire    [COL_ADDR_W-1:0]        cur_blk_col;    //             : top-left position
wire    [15:0]                  cur_blk_data;   //             : block 4x4 bitmap
wire                            cur_blk_act;    //             : is still on active
wire                         left_en;
wire                           right_en;
wire                             up_en;


//==========================================================================
// game state and speed
//==========================================================================
reg game_state = 1'b1; // 1 - started, 0 - puased
reg game_speed = 1'b0; // 0 - normal spend; 1 - 2x speed

reg [25:0] falling_clk_cnt = 26'b0;

assign falling_update = (falling_clk_cnt >= (SPEED_FREQ - 1)) ? game_state : 1'b0;//每过一秒/半秒触发下降信号

always @(posedge clk or negedge rstn) begin
   if (~rstn) begin
      falling_clk_cnt <= 26'b0;
   end 
   else if (falling_clk_cnt >= (SPEED_FREQ - 1)) begin
      falling_clk_cnt <= 26'b0;
   end 
   else if (game_speed) begin
      falling_clk_cnt <= falling_clk_cnt + 26'd2;
   end 
   else begin
      falling_clk_cnt <= falling_clk_cnt + 26'b1;
   end 
end 

always @(posedge clk or negedge rstn) begin
   if (~rstn) begin
      game_state <= 1'b1;
   end 
   else if (pressed_pause_or_start) begin
      game_state <= ~game_state;
   end 
end 

always @(posedge clk or negedge rstn) begin
   if (~rstn) begin
      game_speed <= 1'b0;
   end 
   else if (pressed_speed_up_down) begin
      game_speed <= ~game_speed;
   end 
end 


//==========================================================================
// game score
//==========================================================================

// TODO - add your logic


//==========================================================================
// connnected sub-modules
//==========================================================================

Bitmap #(
   .AREA_ROW(AREA_ROW),
   .AREA_COL(AREA_COL),
   .ROW_ADDR_W(ROW_ADDR_W),
   .COL_ADDR_W(COL_ADDR_W),
   .SPEED_FREQ(SPEED_FREQ)
) u_bitmap (
   .clk(clk),
   .rstn(rstn),
   .falling_update(falling_update),
   .cur_blk_row(cur_blk_row),
   .cur_blk_col(cur_blk_col),
   .cur_blk_data(cur_blk_data),
   .cur_blk_act(cur_blk_act),
   .r1_row(r1_row),
   .r1_data(r1_data),
   .r2_row(r2_row),
   .r2_data(r2_data),
   .game_over(game_over),
   .game_score(game_score),
   .left_en(left_en),
   .right_en(right_en),
   .up_en(up_en)
);


BlockController #(
   .AREA_ROW(AREA_ROW),
   .AREA_COL(AREA_COL),
   .ROW_ADDR_W(ROW_ADDR_W),
   .COL_ADDR_W(COL_ADDR_W)
) u_block_ctrl (
   .clk(clk),
   .rstn(rstn),
   .pressed_left(pressed_left),
   .pressed_right(pressed_right),
   .pressed_up(pressed_up),
   .pressed_down(pressed_down),
   .falling_update(falling_update),
   .cur_blk_row(cur_blk_row),
   .cur_blk_col(cur_blk_col),
   .cur_blk_data(cur_blk_data),
   .cur_blk_act(cur_blk_act),
   .left_en(left_en),
   .right_en(right_en),
   .up_en(up_en)
);


endmodule