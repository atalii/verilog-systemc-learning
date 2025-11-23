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
  input reg [ADDR_WIDTH + 4:0] bus_rx,
  output logic bus_tx_enable,
  input logic bus_tx_sent
);
  logic sending = 0;
  reg should_invalidate = 0;
  reg [ADDR_WIDTH - 1:0] invalidate_addr;

  for (genvar i = 0; i < SET_COUNT; i = i + 1) begin:g_sets
    wire addressed, enable, read_here, write_here, invalidate_here;
    wire [ADDR_WIDTH - $clog2(SET_COUNT) - 1:0] target_addr;

    // Since there's no offset, the cache index occupies the least significant bits.
    assign addressed = in_addr[($clog2(SET_COUNT) - 1):0] == i;
    assign invalidate_here = should_invalidate && addressed;
    assign read_here = read && !invalidate_here;
    assign write_here = write && !invalidate_here;
    assign target_addr = should_invalidate
      ? invalidate_addr[ADDR_WIDTH - 1:$clog2(SET_COUNT)]
      : in_addr[ADDR_WIDTH - 1:$clog2(SET_COUNT)];

    set #(
        .ADDR_WIDTH(ADDR_WIDTH - $clog2(SET_COUNT))
    ) s (
        .enable(addressed),
        .clock(clock),
        .in_addr(target_addr),
        .in_val(in_val),
        .read(read_here),
        .write(write_here),
        .invalidate(invalidate_here),
        .hit(hit),
        .out_val(out_val)
    );
  end

  // Send the right message on the bus while we serve the request. It's not
  // correct to say a request is served until this process finishes, but our
  // cache pins aren't expressive enough for this. 
  //
  // Maybe we'll fix this eventually.
  always @(posedge clock) begin
    if (!sending) begin
      if (read || write) begin
        bus_tx[ADDR_WIDTH + 2:3] <= in_addr;
        bus_tx[3] <= read; // read = 1; write = 0
        bus_tx[2] <= 1;
        bus_tx[1:0] <= ID[1:0];
        bus_tx_enable <= 1;
        sending <= 1;
      end else begin
        bus_tx_enable <= 0;
        bus_tx[0] <= 0;
      end
    end
  end

  always @(posedge clock) begin
    if (bus_rx[2] && bus_rx[1:0] != ID[1:0]) begin
      if (bus_rx[3] == 0) begin
        should_invalidate <= 1;
        invalidate_addr <= bus_rx[ADDR_WIDTH + 2:3];
      end
    end else begin
      should_invalidate <= 0;
    end
  end
endmodule
