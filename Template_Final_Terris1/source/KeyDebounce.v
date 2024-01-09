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
parameter CLK_MAX=CLK_FREQ*20/1000-1; //�������������20ms����

// TODO - based on Lab4 task #2, improve some logic

reg [31:0]cnt_delay=32'd0;
wire [KEY_CNT-1:0]nedge; //��¼keys�½��أ���ʾ��������
wire [KEY_CNT-1:0]pedge; //��¼keys�����أ���ʾ�����ɿ�
reg [KEY_CNT-1:0]key_in_a=KEY_CNT-1'b1111_1111; //�Ĵ�keys����״̬
reg [KEY_CNT-1:0]key_in_b=KEY_CNT-1'b1111_1111; //�Ĵ�keys��ǰһ��״̬

//�����ж�
always @(posedge clk) begin
key_in_a<=keys;
key_in_b<=key_in_a; 
end
assign nedge=(key_in_b)&(~key_in_a); //��������ʱ��ǰ״̬Ϊ1����״̬Ϊ0
assign pedge=(~key_in_b)&(key_in_a); //�����ɿ�ʱ��ǰ״̬Ϊ0����״̬Ϊ1

//��������
always@(posedge clk)begin
if(nedge|pedge)begin
cnt_delay<=32'd0;
end //�������������½��أ���keys�Դ��ڶ���״̬����������

else begin
if(cnt_delay>=CLK_MAX)begin
cnt_delay<=32'd0;
keys_stable_reg<=keys;
end

else begin
cnt_delay<=cnt_delay+32'd1;
end

end //��δ�����������½��أ���ʼ�������ﵽ1s����keys�ѽ����ȶ�״̬���������Ϊ�ﵽ1s�����������
end
assign keys_stable=keys_stable_reg;
endmodule// TODO - add your logic
