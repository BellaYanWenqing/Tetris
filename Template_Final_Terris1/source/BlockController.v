module BlockController #(
   parameter AREA_ROW = 32,
   parameter AREA_COL = 16,
   parameter ROW_ADDR_W = 5,
   parameter COL_ADDR_W = 4
) (
   input                            clk,
   input                            rstn,
   input                            pressed_left,  // key event
   input                            pressed_right, //
   input                            pressed_up,    //
   input                            pressed_down,  //
   input                            falling_update,// block falling signal 
   output   [ROW_ADDR_W-1:0]        cur_blk_row,   // current moving block
   output   [COL_ADDR_W-1:0]        cur_blk_col,   //             : top-left position
   output   [15:0]                  cur_blk_data,  //             : block 4x4 bitmap
   input                            cur_blk_act,  //             : feedback: is still on active
   input                           left_en,
   input                           right_en,
   input                           up_en
);

//==========================================================================
// define basic block, 4 x 4
//==========================================================================

// 田字
reg [15:0] BLK_0 = {
   4'b0_0_0_0,
   4'b0_1_1_0,
   4'b0_1_1_0,
   4'b0_0_0_0
};

//右L
reg [15:0] BLK_1 = {
   4'b0_0_0_0,
   4'b0_1_1_0,
   4'b0_0_1_0,
   4'b0_0_1_0
};

//左L
reg [15:0] BLK_2 = {
   4'b0_0_0_0,
   4'b0_1_1_0,
   4'b0_1_0_0,
   4'b0_1_0_0
};

//右S
reg [15:0] BLK_3 = {
   4'b0_0_0_0,
   4'b0_1_0_0,
   4'b0_1_1_0,
   4'b0_0_1_0
};

//左S
reg [15:0] BLK_4 = {
   4'b0_0_0_0,
   4'b0_0_1_0,
   4'b0_1_1_0,
   4'b0_1_0_0
};

//山形
reg [15:0] BLK_5 = {
   4'b0_0_0_0,
   4'b1_1_1_0,
   4'b0_1_0_0,
   4'b0_0_0_0
};

//长条
reg [15:0] BLK_6 = {
   4'b0_1_0_0,
   4'b0_1_0_0,
   4'b0_1_0_0,
   4'b0_1_0_0
};

//长条
reg [15:0] BLK_7 = {
   4'b0_0_0_0,
   4'b0_0_0_0,
   4'b0_0_0_0,
   4'b1_1_1_1
};


//==========================================================================
// generate next block, 4 x 4
//==========================================================================

reg [10:0] nxt_blk_idx = 10'b0;
reg [15:0] nxt_blk_data;


always @(posedge clk) begin
   // generate fake random number
   nxt_blk_idx <= nxt_blk_idx + 11'd921;
end 

always @(*) begin
   if (^{nxt_blk_idx[10], nxt_blk_idx[8], nxt_blk_idx[6], nxt_blk_idx[4]}) begin
      case({nxt_blk_idx[0], nxt_blk_idx[2], nxt_blk_idx[7]})
         3'd0: nxt_blk_data = BLK_0;
         3'd1: nxt_blk_data = BLK_1;
         3'd2: nxt_blk_data = BLK_2;
         3'd3: nxt_blk_data = BLK_3;
         3'd4: nxt_blk_data = BLK_4;
         3'd5: nxt_blk_data = BLK_5;
         3'd6: nxt_blk_data = BLK_6;
         3'd7: nxt_blk_data = BLK_7;
         default: nxt_blk_data = BLK_0;
      endcase
   end 
   else begin
      case({nxt_blk_idx[1], nxt_blk_idx[3], nxt_blk_idx[5]})
         3'd0: nxt_blk_data = BLK_0;
         3'd1: nxt_blk_data = BLK_1;
         3'd2: nxt_blk_data = BLK_2;
         3'd3: nxt_blk_data = BLK_3;
         3'd4: nxt_blk_data = BLK_4;
         3'd5: nxt_blk_data = BLK_5;
         3'd6: nxt_blk_data = BLK_6;
         3'd7: nxt_blk_data = BLK_7;
         default: nxt_blk_data = BLK_0;
      endcase
   end 
end 



//==========================================================================
// update current block, based on: falling update, pressed keys
//==========================================================================

reg [ROW_ADDR_W-1:0] cur_blk_row_r;
reg [COL_ADDR_W-1:0] cur_blk_col_r;
reg [15:0] cur_blk_data_r;

assign cur_blk_row = cur_blk_row_r;
assign cur_blk_col = cur_blk_col_r;
assign cur_blk_data = cur_blk_data_r;


task reset_cur_blk();
begin
   cur_blk_row_r <= 0;
   cur_blk_col_r <= (AREA_COL >> 1) - 2;
   cur_blk_data_r <= nxt_blk_data;
end 
endtask


always @(posedge clk or negedge rstn) begin
   if (~rstn|~cur_blk_act) begin
      reset_cur_blk();
   end 
   // 1) when current block falling down
   else if (falling_update) begin
      // TODO - add your logic
      cur_blk_row_r<=(cur_blk_act)?cur_blk_row_r+1:cur_blk_row_r;
   end 
   // 2) when has pressed keys - UP (rotate)
   else if (pressed_up) begin
         cur_blk_data_r<=(up_en)?{cur_blk_data_r[12],cur_blk_data_r[8],cur_blk_data_r[4],cur_blk_data_r[0],
                        cur_blk_data_r[13],cur_blk_data_r[9],cur_blk_data_r[5],cur_blk_data_r[1],
                        cur_blk_data_r[14],cur_blk_data_r[10],cur_blk_data_r[6],cur_blk_data_r[2],
                        cur_blk_data_r[15],cur_blk_data_r[11],cur_blk_data_r[7],cur_blk_data_r[3]}:cur_blk_data_r;
// TODO - add your logic
   end 
   // 3) when has pressed keys - DOWN
   else if (pressed_down) begin
      // TODO - add your logic
      cur_blk_row_r<=(cur_blk_act)?cur_blk_row_r+1:cur_blk_row_r;
   end 
   // 4) when has pressed keys - LEFT
   else if (pressed_left) begin
      if(~left_en)cur_blk_col_r<=cur_blk_col_r;
       else if (cur_blk_col_r<=0)cur_blk_col_r<=cur_blk_col_r+15;
          else cur_blk_col_r<=cur_blk_col_r-1;
// TODO - add your logic
   end 
   // 5) when has pressed keys - RIGHT
   else if (pressed_right) begin
      if(~right_en)cur_blk_col_r<=cur_blk_col_r;
      else if (cur_blk_col_r>=15)cur_blk_col_r<=cur_blk_col_r-15;
      else cur_blk_col_r<=cur_blk_col_r+1;
// TODO - add your logic
   end 
end











endmodule