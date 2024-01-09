
`define SEG_SEL_NULL  6'b00_0000
`define SEG_SEL_0     6'b00_0001
`define SEG_SEL_1     6'b00_0010
`define SEG_SEL_2     6'b00_0100
`define SEG_SEL_3     6'b00_1000
`define SEG_SEL_4     6'b01_0000
`define SEG_SEL_5     6'b10_0000

// `define SEG_FLASH_DUR 26'd49_999

module SegWrapper #(
   parameter CLK_FREQ = 50_000_000,
   parameter SEG_FLASH_DUR = 49_999
) (
   input                            clk,
   input                            rstn,
   input      [9:0]                 game_score,
   output     [5:0]                 seg_sel,
   output     [7:0]                 seg_data
);

reg [5:0] seg_sel_r = 5'b0;
reg [7:0] seg_data_r = 8'hff;

assign seg_sel = seg_sel_r;
assign seg_data = seg_data_r;


// TODO - add your logic
wire [3:0] seg_num_0; // display number for segment digital tube #0 
wire [3:0] seg_num_1; // display number for segment digital tube #1
wire [3:0] seg_num_2; // display number for segment digital tube #2 
wire [3:0] seg_num_3; // display number for segment digital tube #3 
wire [3:0] seg_num_4; // display number for segment digital tube #4 
wire [3:0] seg_num_5; // display number for segment digital tube #5 

assign seg_num_5=4'd0;
assign seg_num_4=4'd0;
assign seg_num_3=game_score%10;
assign seg_num_2=(game_score/10)%10;
assign seg_num_1=(game_score/100)%10;
assign seg_num_0=(game_score/1000)%10;

reg [31:0] clk_cnt = 32'd0;
assign scan_next = (clk_cnt == SEG_FLASH_DUR);

always @(posedge clk or negedge rstn) begin
// reset 
if (rstn == 1'b0) begin
clk_cnt <= 32'b0;
end 
else begin
// clk counter
if (clk_cnt == SEG_FLASH_DUR) begin
clk_cnt <= 32'b0;
end 
else begin
clk_cnt <= clk_cnt + 32'b1;
end
end 
end


//for seg_sel
reg [5:0] next_seg_sel = `SEG_SEL_NULL;

//  for seg_sel, 1)//
always @(posedge clk or negedge rstn) begin
if (rstn == 1'b0) begin
seg_sel_r <= `SEG_SEL_NULL;
end 
else begin
seg_sel_r <= next_seg_sel;
end 
end 

// for seg_sel, 2)
always @(*) begin
case(seg_sel)
`SEG_SEL_NULL: next_seg_sel=scan_next?`SEG_SEL_0:seg_sel;
`SEG_SEL_0: next_seg_sel=scan_next?`SEG_SEL_1:seg_sel;
`SEG_SEL_1: next_seg_sel=scan_next?`SEG_SEL_2:seg_sel;
`SEG_SEL_2: next_seg_sel=scan_next?`SEG_SEL_3:seg_sel;
`SEG_SEL_3: next_seg_sel=scan_next?`SEG_SEL_4:seg_sel;
`SEG_SEL_4: next_seg_sel=scan_next?`SEG_SEL_5:seg_sel;
`SEG_SEL_5: next_seg_sel=scan_next?`SEG_SEL_0:seg_sel;
default:next_seg_sel=seg_sel;
endcase
// TODO - update next_seg_sel, based on seg_sel, and inner signal scan_next
// TODO - next_seg_sel = ??
end

// for seg_sel, 3)  sel_num & seg_data

reg [3:0] sel_num = 4'b0;

always @(posedge clk or negedge rstn)
begin
if (rstn == 1'b0) begin
sel_num = 4'b0;
end 
// TODO - udpate sel_num, based on seg_sel
else begin
case(seg_sel)
`SEG_SEL_NULL: sel_num=4'd0;
`SEG_SEL_0: sel_num=seg_num_0;
`SEG_SEL_1: sel_num=seg_num_1;
`SEG_SEL_2: sel_num=seg_num_2;
`SEG_SEL_3: sel_num=seg_num_3;
`SEG_SEL_4: sel_num=seg_num_4;
`SEG_SEL_5: sel_num=seg_num_5;
default:sel_num=4'd0;
endcase
end 
end

// combination logic, output: seg_data, based on sel_num
always @(*)
begin
case(sel_num)
4'd0: seg_data_r = 8'b1100_0000;
4'd1: seg_data_r = 8'b1111_1001;
4'd2: seg_data_r = 8'b1010_0100;
4'd3: seg_data_r = 8'b1011_0000;
4'd4: seg_data_r = 8'b1001_1001;
4'd5: seg_data_r = 8'b1001_0010;
4'd6: seg_data_r = 8'b1000_0010;
4'd7: seg_data_r = 8'b1111_1000;
4'd8: seg_data_r = 8'b1000_0000;
4'd9: seg_data_r = 8'b1001_0000;
4'ha: seg_data_r = 8'b1000_1000;
4'hb: seg_data_r = 8'b1000_0011;
4'hc: seg_data_r = 8'b1100_0110;
4'hd: seg_data_r = 8'b1010_0001;
4'he: seg_data_r = 8'b1000_0110;
4'hf: seg_data_r = 8'b1000_1110;
default:seg_data_r = 8'b1100_0000;
endcase
end

endmodule