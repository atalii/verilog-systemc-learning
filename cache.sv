module cache #(
  parameter integer SET_COUNT = 2,
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2
)(
  input wire clock,
  input wire [ADDR_WIDTH - 1:0] ch1_in_addr,
  input wire [LINE_WIDTH - 1:0] ch1_in_val,
  input wire ch1_read,
  input wire ch1_write,
  output reg ch1_hit,
  output reg [LINE_WIDTH - 1:0] ch1_out_val,

  input wire [ADDR_WIDTH - 1:0] ch2_in_addr,
  input wire ch2_read,
  output reg ch2_hit,
  output reg [LINE_WIDTH - 1:0] ch2_out_val
);
  for (genvar i = 0; i < SET_COUNT; i = i + 1) begin:g_sets
    wire addressed;
    assign addressed = ch1_in_addr[$clog2(SET_COUNT) - 1:0] == i;

    set s (
        .enable(addressed),
        .clock(clock),
        .ch1_in_addr(ch1_in_addr),
        .ch1_in_val(ch1_in_val),
        .ch1_read(ch1_read),
        .ch1_write(ch1_write),
        .ch1_hit(ch1_hit),
        .ch1_out_val(ch1_out_val),
        .ch2_in_addr(ch2_in_addr),
        .ch2_read(ch2_read),
        .ch2_hit(ch2_hit),
        .ch2_out_val(ch2_out_val)
    );
  end
endmodule
