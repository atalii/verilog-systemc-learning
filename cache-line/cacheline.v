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

  // Initialized at 1. When this goes to 0, eviction is okay.
  reg clock_counter;

  always @(posedge clock) begin
    if (read) begin
      assign out_val = stored_val;
      assign hit = stored_addr == in_addr;
      if (hit) assign clock_counter = 1;

    end else if (write) begin
      assign hit = ~clock_counter | (in_addr == stored_addr);
      assign clock_counter = hit;
      if (hit) begin
        stored_addr = in_addr;
        stored_val  = in_val;
      end
    end
    ;
  end
endmodule
