module cacheline (
    in_addr,
    in_val,
    read,
    write,
    clock,
    hit,
    out_val
);
  input reg [7:0] in_addr;
  input reg [31:0] in_val;
  input wire read, write, clock;

  output reg [31:0] out_val;
  output reg hit;

  reg [7:0] stored_addr;
  reg [31:0] stored_val;
  // use a control bit and r/w

  // Set to 1 at an access.
  reg clock_counter;

  assign out_val = stored_val;

  always @(posedge clock) begin
    hit <= read & (stored_addr == in_addr);
    clock_counter <= clock_counter | (stored_addr == in_addr);
  end

  always @(posedge clock) begin
    if (write) begin
      hit <= !clock_counter | (in_addr == stored_addr);
      if (!clock_counter | in_addr == stored_addr) begin
        stored_addr <= in_addr;
        stored_val  <= in_val;
      end

      clock_counter <= !clock_counter | (in_addr == stored_addr);
    end
  end
endmodule
