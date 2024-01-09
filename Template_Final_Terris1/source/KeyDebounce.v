module KeyDebounce #(
                              // clock frequency(Mhz), 50 MHz
   parameter CLK_FREQ = 50_000_000,
   parameter KEY_CNT = 8
)
(
   input                clk,               // clock input
   input  [KEY_CNT-1:0] keys,              // input key pins, raw input
   output [KEY_CNT-1:0] keys_stable        // output stable key status, 0 - press down
);

reg [KEY_CNT-1:0] keys_stable_reg;
parameter CLK_MAX=CLK_FREQ*20/1000-1; //定义参数，用于20ms计数

// TODO - based on Lab4 task #2, improve some logic

reg [31:0]cnt_delay=32'd0;
wire [KEY_CNT-1:0]nedge; //记录keys下降沿，表示按键按下
wire [KEY_CNT-1:0]pedge; //记录keys上升沿，表示按键松开
reg [KEY_CNT-1:0]key_in_a=KEY_CNT-1'b1111_1111; //寄存keys的现状态
reg [KEY_CNT-1:0]key_in_b=KEY_CNT-1'b1111_1111; //寄存keys的前一个状态

//边沿判断
always @(posedge clk) begin
key_in_a<=keys;
key_in_b<=key_in_a; 
end
assign nedge=(key_in_b)&(~key_in_a); //按键按下时，前状态为1，现状态为0
assign pedge=(~key_in_b)&(key_in_a); //按键松开时，前状态为0，现状态为1

//按键消抖
always@(posedge clk)begin
if(nedge|pedge)begin
cnt_delay<=32'd0;
end //若出现上升或下降沿，则keys仍处于抖动状态，计数清零

else begin
if(cnt_delay>=CLK_MAX)begin
cnt_delay<=32'd0;
keys_stable_reg<=keys;
end

else begin
cnt_delay<=cnt_delay+32'd1;
end

end //若未出现上升或下降沿，开始计数，达到1s，则keys已进入稳定状态，可输出；为达到1s，则继续计数
end
assign keys_stable=keys_stable_reg;
endmodule// TODO - add your logic
