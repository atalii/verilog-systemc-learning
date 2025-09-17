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

  // Set to 1 at an access.
  reg clock_counter;

  always @(posedge clock) begin
    if (read) begin
      assign out_val = stored_val;
      assign hit = stored_addr == in_addr;
    end else if (write) begin
      assign hit = ~clock_counter | (in_addr == stored_addr);
      if (hit) begin
        stored_addr = in_addr;
        stored_val  = in_val;
      end
    end
    ;

    assign clock_counter = hit;
  end
endmodule
