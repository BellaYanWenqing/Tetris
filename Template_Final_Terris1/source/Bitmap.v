`define __DEBUG__


module Bitmap #(
   parameter AREA_ROW = 32,
   parameter AREA_COL = 16,
   parameter ROW_ADDR_W = 5,
   parameter COL_ADDR_W = 4,
   parameter SPEED_FREQ = 50_000_000
)
(
   input                            clk,
   input                            rstn,
   input                            falling_update,// block falling signal
   input    [ROW_ADDR_W-1:0]        cur_blk_row,   // current moving block
   input    [COL_ADDR_W-1:0]        cur_blk_col,   //             : top-left position
   input    [15:0]                  cur_blk_data,  //             : block 4x4 bitmap
   output                           cur_blk_act,   //             : is still on active
   input    [ROW_ADDR_W-1:0]        r1_row,        // output channel #1
   output   [AREA_COL*2-1:0]        r1_data,       //         : data
   input    [ROW_ADDR_W-1:0]        r2_row,        // output channel #1
   output   [AREA_COL*2-1:0]        r2_data,       //         : data
   output                           game_over,
   output         [9:0]                  game_score,
   output                           left_en,
   output                           right_en,
   output                           up_en
);

//==========================================================================
// bitmap content
//==========================================================================

reg [AREA_COL - 1 : 0] bitmap_h [AREA_ROW - 1 : 0];
reg [AREA_COL - 1 : 0] bitmap_parrallel [AREA_ROW - 1 : 0];
reg [AREA_COL - 1 : 0] bitmap_pos [AREA_ROW - 1 : 0];
reg [AREA_COL - 1 : 0] bitmap_delay [AREA_ROW - 1 : 0];
reg [AREA_COL - 1 : 0] bitmap_l [AREA_ROW - 1 : 0];
reg [AREA_COL - 1 : 0] bitmap_l_next [AREA_ROW - 1 : 0];


`ifdef __DEBUG__
wire [AREA_COL - 1 : 0] bitmap_h24 = bitmap_h[24];
wire [AREA_COL - 1 : 0] bitmap_h25 = bitmap_h[25];
wire [AREA_COL - 1 : 0] bitmap_h26 = bitmap_h[26];
wire [AREA_COL - 1 : 0] bitmap_h27 = bitmap_h[27];
wire [AREA_COL - 1 : 0] bitmap_h28 = bitmap_h[28];
wire [AREA_COL - 1 : 0] bitmap_h29 = bitmap_h[29];
wire [AREA_COL - 1 : 0] bitmap_h30 = bitmap_h[30];
wire [AREA_COL - 1 : 0] bitmap_h31 = bitmap_h[31];

wire [AREA_COL - 1 : 0] bitmap_l0 = bitmap_l[0];
wire [AREA_COL - 1 : 0] bitmap_l1 = bitmap_l[1];
wire [AREA_COL - 1 : 0] bitmap_l2 = bitmap_l[2];
wire [AREA_COL - 1 : 0] bitmap_l3 = bitmap_l[3];
wire [AREA_COL - 1 : 0] bitmap_l10 = bitmap_l[10];
wire [AREA_COL - 1 : 0] bitmap_l11 = bitmap_l[11];
wire [AREA_COL - 1 : 0] bitmap_l12 = bitmap_l[12];
wire [AREA_COL - 1 : 0] bitmap_l13 = bitmap_l[13];
wire [AREA_COL - 1 : 0] bitmap_l20 = bitmap_l[20];
wire [AREA_COL - 1 : 0] bitmap_l21 = bitmap_l[21];
wire [AREA_COL - 1 : 0] bitmap_l22 = bitmap_l[22];
wire [AREA_COL - 1 : 0] bitmap_l23 = bitmap_l[23];
wire [AREA_COL - 1 : 0] bitmap_l28 = bitmap_l[28];
wire [AREA_COL - 1 : 0] bitmap_l29 = bitmap_l[29];
wire [AREA_COL - 1 : 0] bitmap_l30 = bitmap_l[30];
wire [AREA_COL - 1 : 0] bitmap_l31 = bitmap_l[31];
`endif
/*reg [31:0]full_row;
wire [2:0]full_row_num;
assign full_row_num=full_row[0]+full_row[1]+full_row[2]+full_row[3]+full_row[4]+full_row[5]+full_row[6]+full_row[7]+full_row[8]+full_row[9]+full_row[10]+full_row[11]+full_row[12]+full_row[13]+full_row[14]+full_row[15]+full_row[16]+full_row[17]+full_row[18]+full_row[19]+full_row[20]+full_row[21]+full_row[22]+full_row[23]+full_row[24]+full_row[25]+full_row[26]+full_row[27]+full_row[28]+full_row[29]+full_row[30]+full_row[31];
;*/

reg [9:0] game_score_r=10'b0;
assign game_score=game_score_r;
wire [2:0]full_row_num;
assign full_row_num=(bitmap_h[0]==16'hffff)+
(bitmap_h[1]==16'hffff)+
(bitmap_h[2]==16'hffff)+
(bitmap_h[3]==16'hffff)+
(bitmap_h[4]==16'hffff)+
(bitmap_h[5]==16'hffff)+
(bitmap_h[6]==16'hffff)+
(bitmap_h[7]==16'hffff)+
(bitmap_h[8]==16'hffff)+
(bitmap_h[9]==16'hffff)+
(bitmap_h[10]==16'hffff)+
(bitmap_h[11]==16'hffff)+
(bitmap_h[12]==16'hffff)+
(bitmap_h[13]==16'hffff)+
(bitmap_h[14]==16'hffff)+
(bitmap_h[15]==16'hffff)+
(bitmap_h[16]==16'hffff)+
(bitmap_h[17]==16'hffff)+
(bitmap_h[18]==16'hffff)+
(bitmap_h[19]==16'hffff)+
(bitmap_h[20]==16'hffff)+
(bitmap_h[21]==16'hffff)+
(bitmap_h[22]==16'hffff)+
(bitmap_h[23]==16'hffff)+
(bitmap_h[24]==16'hffff)+
(bitmap_h[25]==16'hffff)+
(bitmap_h[26]==16'hffff)+
(bitmap_h[27]==16'hffff)+
(bitmap_h[28]==16'hffff)+
(bitmap_h[29]==16'hffff)+
(bitmap_h[30]==16'hffff)+
(bitmap_h[31]==16'hffff);
reg act_delay;
always @(posedge clk) begin
act_delay <= cur_blk_act;
end
wire act_posedge;

assign act_posedge=(~act_delay)&cur_blk_act;

always@(posedge clk or negedge rstn)begin
if(~rstn)
game_score_r<=10'd0;
else begin
if(act_posedge) begin
case(full_row_num)
3'd1:game_score_r<=game_score_r+10'd1;
3'd2:game_score_r<=game_score_r+10'd2;
3'd3:game_score_r<=game_score_r+10'd4;
3'd4:game_score_r<=game_score_r+10'd8;
default:game_score_r<=game_score_r;
endcase
end
end
end
generate
genvar i;
for (i = 31; i >=0; i = i-1) begin
   if (i > 0) begin 
      always @(posedge clk or negedge rstn) begin
         if (~rstn) begin
            bitmap_h[i] <= 16'h0;
         end 
         else if(cur_blk_act) begin
         bitmap_delay[i]<=bitmap_parrallel[i];
         bitmap_pos[i] <= (~bitmap_delay[i])&&bitmap_parrallel[i];
          if(i<31) begin
             if(bitmap_h[i]==16'hffff) begin
             bitmap_h[i] <= bitmap_h[i-1];
             bitmap_parrallel[i]<=0; 
             end
             else if(bitmap_h[i+1]==16'hffff) begin
             bitmap_h[i]<=bitmap_h[i-1];
             bitmap_parrallel[i]<=16'hffff; 
             end
             else if(bitmap_pos[i+1]) begin
             bitmap_h[i]<=bitmap_h[i-1];
             bitmap_parrallel[i]<=16'hffff; 
             end
             else begin
             bitmap_h[i] <= bitmap_h[i]; 
             bitmap_parrallel[i]<= 0; 
             end 
          end
          else begin//i=31
             if(bitmap_h[i]==16'hffff) begin
             bitmap_h[i]<=bitmap_h[i-1]; 
             end
             else bitmap_h[i]<=bitmap_h[i]; 
          end 
        end
       else begin
       bitmap_h[i] <= bitmap_h[i]|bitmap_l[i];
       bitmap_parrallel [i]<=0;
      end
           
   end 
      end

   else begin // when i = 0
      always @(posedge clk or negedge rstn) begin
         if (~rstn) begin
            bitmap_h[i] <= 16'h0;
         end 
         else begin
            if(!cur_blk_act)
            bitmap_h[i]<=bitmap_l[i]|bitmap_h[i] ;
             else if (bitmap_h[i] == 16'hffff)
             bitmap_h[i] <=16'h0; 
             else bitmap_h[i] <= bitmap_h[i];
         end 
      end
   end 
end

endgenerate


//==========================================================================
// moving block
//==========================================================================

generate
genvar j;
for (j = 0; j < AREA_ROW; j = j+1) begin
   always @(posedge clk or negedge rstn) begin
      if (~rstn) begin
         bitmap_l[j] <= 0;
      end 
      else begin
         if (j == cur_blk_row) begin
            bitmap_l[j] <= (({12'b0, cur_blk_data[3:0]} << cur_blk_col)|({12'b0, cur_blk_data[3:0]} >>(16- cur_blk_col)));
         end 
         else if (j == cur_blk_row + 1) begin
            bitmap_l[j] <= (({12'b0, cur_blk_data[7:4]} << cur_blk_col)|({12'b0, cur_blk_data[7:4]} >>(16- cur_blk_col)));
         end 
         else if (j == cur_blk_row + 2) begin
            bitmap_l[j] <= (({12'b0, cur_blk_data[11:8]} << cur_blk_col)|({12'b0, cur_blk_data[11:8]} >> (16-cur_blk_col)));
         end
         else if (j == cur_blk_row + 3) begin
            bitmap_l[j] <= (({12'b0, cur_blk_data[15:12]} << cur_blk_col)|({12'b0, cur_blk_data[15:12]} >> (16- cur_blk_col)));
         end
         else begin
            bitmap_l[j] <= 0;
         end  
      end 
   end
end 
endgenerate


//==========================================================================
// output channel #1
//==========================================================================

wire [AREA_COL-1:0] r1_data_h = bitmap_h[r1_row];
wire [AREA_COL-1:0] r1_data_l = bitmap_l[r1_row];

assign r1_data = {r1_data_h, r1_data_l};


//==========================================================================
// output channel #2
//==========================================================================

reg [2*AREA_COL-1:0] r2_data_r;
assign r2_data = r2_data_r;

always @(*) begin
   r2_data_r <= {bitmap_h[r2_row], bitmap_l[r2_row]};
end 


//==========================================================================
// TODO - add your logic
//==========================================================================
reg [15:0]cur_blk_data_next;
always@(*)
 cur_blk_data_next<={cur_blk_data[12],cur_blk_data[8],cur_blk_data[4],cur_blk_data[0],
                        cur_blk_data[13],cur_blk_data[9],cur_blk_data[5],cur_blk_data[1],
                        cur_blk_data[14],cur_blk_data[10],cur_blk_data[6],cur_blk_data[2],
                        cur_blk_data[15],cur_blk_data[11],cur_blk_data[7],cur_blk_data[3]};
generate
genvar m;
for (m = 0; m < AREA_ROW; m = m+1) begin
   always @(posedge clk or negedge rstn) begin
      if (~rstn) begin
         bitmap_l_next[m] <= 0;
      end 
      else begin
         if (m == cur_blk_row) begin
            bitmap_l_next[m] <= (({12'b0, cur_blk_data_next[3:0]} << cur_blk_col)|({12'b0, cur_blk_data_next[3:0]} >>(16- cur_blk_col)));
         end 
         else if (m == cur_blk_row + 1) begin
            bitmap_l_next[m] <= (({12'b0, cur_blk_data_next[7:4]} << cur_blk_col)|({12'b0, cur_blk_data_next[7:4]} >>(16- cur_blk_col)));
         end 
         else if (m == cur_blk_row + 2) begin
            bitmap_l_next[m] <= (({12'b0, cur_blk_data_next[11:8]} << cur_blk_col)|({12'b0, cur_blk_data_next[11:8]} >> (16-cur_blk_col)));
         end
         else if (m == cur_blk_row + 3) begin
            bitmap_l_next[m] <= (({12'b0, cur_blk_data_next[15:12]} << cur_blk_col)|({12'b0, cur_blk_data_next[15:12]} >>(16- cur_blk_col)));
         end
         else begin
            bitmap_l_next[m] <= 0;
         end  
      end 
   end
end 
endgenerate

assign up_en=((bitmap_l_next[cur_blk_row]&bitmap_h[cur_blk_row])==0)&
((bitmap_l_next[cur_blk_row+1]&bitmap_h[cur_blk_row+1])==0)&
((bitmap_l_next[cur_blk_row+2]&bitmap_h[cur_blk_row+2])==0)&
((bitmap_l_next[cur_blk_row+3]&bitmap_h[cur_blk_row+3])==0)&
((bitmap_l_next[cur_blk_row][0]==0)|(bitmap_l_next[cur_blk_row][15]==0))&
((bitmap_l_next[cur_blk_row+1][0]==0)|(bitmap_l_next[cur_blk_row+1][15]==0))&
((bitmap_l_next[cur_blk_row+2][0]==0)|(bitmap_l_next[cur_blk_row+2][15]==0))&
((bitmap_l_next[cur_blk_row+3][0]==0)|(bitmap_l_next[cur_blk_row+3][15]==0));

assign left_en=(((bitmap_l[cur_blk_row]>>1)&bitmap_h[cur_blk_row])==0)&
(((bitmap_l[cur_blk_row+1]>>1)&bitmap_h[cur_blk_row+1])==0)&
(((bitmap_l[cur_blk_row+2]>>1)&bitmap_h[cur_blk_row+2])==0)&
(((bitmap_l[cur_blk_row+3]>>1)&bitmap_h[cur_blk_row+3])==0)&
(bitmap_l[cur_blk_row][0]==0)&
(bitmap_l[cur_blk_row+1][0]==0)&
(bitmap_l[cur_blk_row+2][0]==0)&
(bitmap_l[cur_blk_row+3][0]==0);

assign right_en=(((bitmap_l[cur_blk_row]<<1)&bitmap_h[cur_blk_row])==0)&
(((bitmap_l[cur_blk_row+1]<<1)&bitmap_h[cur_blk_row+1])==0)&
(((bitmap_l[cur_blk_row+2]<<1)&bitmap_h[cur_blk_row+2])==0)&
(((bitmap_l[cur_blk_row+3]<<1)&bitmap_h[cur_blk_row+3])==0)&
(bitmap_l[cur_blk_row][15]==0)&
(bitmap_l[cur_blk_row+1][15]==0)&
(bitmap_l[cur_blk_row+2][15]==0)&
(bitmap_l[cur_blk_row+3][15]==0);



wire cur_blk_act;
assign cur_blk_act =(bitmap_l[31] == 16'b0)&
                    ((bitmap_h[1]&bitmap_l[0])==0)&
                    ((bitmap_h[2]&bitmap_l[1])==0)&
                    ((bitmap_h[3]&bitmap_l[2])==0)&
                    ((bitmap_h[4]&bitmap_l[3])==0)&
                    ((bitmap_h[5]&bitmap_l[4])==0)&
                    ((bitmap_h[6]&bitmap_l[5])==0)&
                    ((bitmap_h[7]&bitmap_l[6])==0)&
                    ((bitmap_h[8]&bitmap_l[7])==0)&
                    ((bitmap_h[9]&bitmap_l[8])==0)&
                    ((bitmap_h[10]&bitmap_l[9])==0)&
                    ((bitmap_h[11]&bitmap_l[10])==0)&
                    ((bitmap_h[12]&bitmap_l[11])==0)&
                    ((bitmap_h[13]&bitmap_l[12])==0)&
                    ((bitmap_h[14]&bitmap_l[13])==0)&
                    ((bitmap_h[15]&bitmap_l[14])==0)&
                    ((bitmap_h[16]&bitmap_l[15])==0)&
                    ((bitmap_h[17]&bitmap_l[16])==0)&
                    ((bitmap_h[18]&bitmap_l[17])==0)&
                    ((bitmap_h[19]&bitmap_l[18])==0)&
                    ((bitmap_h[20]&bitmap_l[19])==0)&
                    ((bitmap_h[21]&bitmap_l[20])==0)&
                    ((bitmap_h[22]&bitmap_l[21])==0)&
                    ((bitmap_h[23]&bitmap_l[22])==0)&
                    ((bitmap_h[24]&bitmap_l[23])==0)&
                    ((bitmap_h[25]&bitmap_l[24])==0)&
                    ((bitmap_h[26]&bitmap_l[25])==0)&
                    ((bitmap_h[27]&bitmap_l[26])==0)&
                    ((bitmap_h[28]&bitmap_l[27])==0)&
                    ((bitmap_h[29]&bitmap_l[28])==0)&
                    ((bitmap_h[30]&bitmap_l[29])==0)&
                    ((bitmap_h[31]&bitmap_l[30])==0);

assign game_over=(bitmap_h[0]!=0);
endmodule