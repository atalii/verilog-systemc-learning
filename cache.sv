module cache #(
  parameter integer SET_COUNT = 2,
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2,
  parameter integer ID = 2
)(
  input wire clock,
  input wire [ADDR_WIDTH - 1:0] in_addr,
  input wire [LINE_WIDTH - 1:0] in_val,
  input wire read,
  input wire write,
  output reg hit,
  output reg [LINE_WIDTH - 1:0] out_val,

  output reg [ADDR_WIDTH + 4:0] bus_tx,
  output logic bus_tx_enable,
  input logic bus_tx_sent
);
  logic sending = 0;

  for (genvar i = 0; i < SET_COUNT; i = i + 1) begin:g_sets
    wire addressed;
    wire enable;

    // Since there's no offset, the cache index occupies the least significant bits.
    assign addressed = in_addr[($clog2(SET_COUNT) - 1):0] == i;

    set #(
        .ADDR_WIDTH(ADDR_WIDTH - $clog2(SET_COUNT))
    ) s (
        .enable(addressed),
        .clock(clock),
        .in_addr(in_addr[ADDR_WIDTH - 1:$clog2(SET_COUNT)]),
        .in_val(in_val),
        .read(read),
        .write(write),
        .hit(hit),
        .out_val(out_val)
    );
  end

  // Send the right message on the bus while we serve the request. There are two cases:
  // 1. We finish serving the request before we can send on the bus.
  //    * Don't consider the request complete until we finish sending. In
  //      some edge cases, we don't have the information from the set needed
  //      to decide when this occurs. That's a bug, but I'm deciding it's
  //      fine to have that here now.
  // 2. We finish sending on the bus before we finish processing the request.
  //    * This is totally fine. Other caches may prematurely invalidate, but
  //      since we're not doing write-back or write-through, it's fine.
  always @(posedge clock) begin
    if (!sending) begin
      if (read || write) begin
        bus_tx[ADDR_WIDTH + 2:3] <= in_addr;
        bus_tx[2] <= 1;
        bus_tx[3] <= read ? 1 : write;
        bus_tx[1:0] <= ID[1:0];
        bus_tx_enable <= 1;
        sending <= 1;
      end else begin
        bus_tx_enable <= 0;
        bus_tx[0] <= 0;
      end
    end
  end
endmodule
