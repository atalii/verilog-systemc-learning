module cache #(
  parameter integer SET_COUNT = 2,
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2
)(
  input wire clock,
  input wire [ADDR_WIDTH - 1:0] in_addr,
  input wire [LINE_WIDTH - 1:0] in_val,
  input wire read,
  input wire write,
  output reg hit,
  output reg [LINE_WIDTH - 1:0] out_val
);
  for (genvar i = 0; i < SET_COUNT; i = i + 1) begin:g_sets
    wire addressed;
    assign addressed = in_addr[$clog2(SET_COUNT) - 1:0] == i;

    set s (
        .enable(addressed),
        .clock(clock),
        .in_addr(in_addr),
        .in_val(in_val),
        .read(read),
        .write(write),
        .hit(hit),
        .out_val(out_val)
    );
  end
endmodule
