module Top #(
    parameter CLK_FREQ = 32'd50_000_000
) (
    input             clk,
    input      [7:0]  keys, 
    output            uart_tx,
    output reg [7:0]  led,
    output     [5:0]  seg_sel,
    output     [7:0]  seg_data,
                                     // Chip ms72xx
    output            iic_tx_scl    ,
    inout             iic_tx_sda    ,
    output            rstn_out      ,
                                     // HDMI output 
    output            pix_clk       , // 148.5Mhz                           
    output            vs_out        , 
    output            hs_out        , 
    output            de_out        ,
    output     [7:0]  r_out         , 
    output     [7:0]  g_out         , 
    output     [7:0]  b_out  
);

//==========================================================================
// internal signals
//==========================================================================

wire rstn = keys[7];

parameter AREA_ROW = 32;
parameter AREA_COL = 16;
parameter ROW_ADDR_W = 5;
parameter COL_ADDR_W = 4;

wire [ROW_ADDR_W-1:0] hdmi_bitmap_row;//五位行地址
wire [AREA_COL*2-1:0] hdmi_bitmap_data;//2行

wire [ROW_ADDR_W-1:0] uart_bitmap_row;
wire [AREA_COL*2-1:0] uart_bitmap_data;


//==========================================================================
// PLL, generate 148.5M & 10M clk
//==========================================================================
wire pll_lock;
wire clk_10m;

PLL_148M5 u_pll (
  .clkin1(clk),             // input
  .pll_lock(pll_lock),      // output
  .clkout0(pix_clk),        // output
  .clkout1(clk_10m)         // output
);

//==========================================================================
// HDMI Wrapper, display output
//==========================================================================
wire hdmi_init_over;

HdmiWrapper u_hdmi (
   .rstn(pll_lock)            , // pll lock
   .cfg_clk(clk_10m)          , // 10Mhz
   .iic_tx_scl(iic_tx_scl)    ,
   .iic_tx_sda(iic_tx_sda)    ,
   .init_over(hdmi_init_over) ,
   .rstn_out(rstn_out)        ,
                                // HDMI output 
   .pix_clk(pix_clk)          , // 148.5Mhz                           
   .vs_out(vs_out)            , 
   .hs_out(hs_out)            , 
   .de_out(de_out)            ,
   .r_out(r_out)              , 
   .g_out(g_out)              , 
   .b_out(b_out)              , 
   .bitmap_row(hdmi_bitmap_row),
   .bitmap_data(hdmi_bitmap_data)
);


//==========================================================================
// Key debounce & filter
//==========================================================================

wire [6:0] keys_stable;

reg  [6:0] keys_d1 = 7'h7f; // keys_stable with 1 clock delay 

wire pressed_left           = keys_d1[0] & (~keys_stable[0]);
wire pressed_right          = keys_d1[1] & (~keys_stable[1]);
wire pressed_down           = keys_d1[2] & (~keys_stable[2]);
wire pressed_up             = keys_d1[3] & (~keys_stable[3]);
wire pressed_reserverd      = keys_d1[4] & (~keys_stable[4]);
wire pressed_speed_up_down  = keys_d1[5] & (~keys_stable[5]);
wire pressed_pause_or_start = keys_d1[6] & (~keys_stable[6]);

KeyDebounce #(
   .CLK_FREQ(CLK_FREQ),
   .KEY_CNT(7)
) u_key (
   .clk(clk), 
   .keys(keys[6:0]),
   .keys_stable(keys_stable)
);

always @(posedge clk) begin
   keys_d1 <= keys_stable;
end 


//==========================================================================
// Game wrapper, including core logic
//==========================================================================
wire game_over;
wire game_falling_update;
wire [9:0] game_score;

Wrapper #(
   .AREA_ROW(AREA_ROW),
   .AREA_COL(AREA_COL),
   .ROW_ADDR_W(ROW_ADDR_W),
   .COL_ADDR_W(COL_ADDR_W),
   .SPEED_FREQ(CLK_FREQ)
) u_wrapper (
   .clk(clk),
   .rstn(rstn),
   .pressed_left(pressed_left),     // key event
   .pressed_right(pressed_right),   //
   .pressed_down(pressed_down),     //
   .pressed_up(pressed_up),         //
   .pressed_speed_up_down(pressed_speed_up_down),
   .pressed_pause_or_start(pressed_pause_or_start),
   .r1_row(hdmi_bitmap_row),  // output channel #1
   .r1_data(hdmi_bitmap_data),//
   .r2_row(uart_bitmap_row),  // output channel #2
   .r2_data(uart_bitmap_data),//
   .falling_update(game_falling_update),
   .game_score(game_score),
   .game_over(game_over)
);


//==========================================================================
// uart wrapper, bitmap data send to PC
//==========================================================================

UartWrapper #(
   .AREA_ROW(AREA_ROW),
   .AREA_COL(AREA_COL),
   .ROW_ADDR_W(ROW_ADDR_W),
   .COL_ADDR_W(COL_ADDR_W),
   .CLK_FREQ(CLK_FREQ)
) u_uart (
   .clk(clk),
   .rstn(rstn),
   .uart_tx(uart_tx),
   .bitmap_row(uart_bitmap_row), 
   .bitmap_data(uart_bitmap_data)
);


//==========================================================================
// seg display for game score
//==========================================================================

SegWrapper #(
   .CLK_FREQ(CLK_FREQ)
) u_seg (
   .clk(clk),
   .rstn(rstn),
   .game_score(game_score),
   .seg_sel(seg_sel), 
   .seg_data(seg_data)
);


//==========================================================================
// LED as status
//==========================================================================

always @(posedge clk or negedge rstn) begin 
   if (~rstn) begin
      led[7:0] <= 8'h01;
   end 
   else if (~(&keys_stable)) begin
      led[7:0] <= {1'b0, ~keys_stable};
   end 
   else if (game_falling_update) begin
      if (game_over) begin
         led <= (led == 8'hff) ? 8'h00 : 8'hff;
      end 
      else begin
         led[7:0] <= {led[6:0], led[7]};
      end 
   end 
end 

endmodule