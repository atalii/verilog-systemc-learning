module cacheline (
    in_addr,
    in_val,
    read,
    write,
    clock,
    force_write,
    hit,
    out_val
);
  input reg [7:0] in_addr;
  input reg [31:0] in_val;
  input wire read, write, clock, force_write;

  output reg [31:0] out_val;
  output reg hit;

  reg [ 7:0] stored_addr;
  reg [31:0] stored_val;

  always @(posedge clock) begin
    if (read) begin
      assign hit = stored_addr == in_addr;
      assign out_val = stored_val;
    end else if (write) begin
      assign hit = in_addr == stored_addr;
      if (hit | force_write) stored_val = in_val;
    end
    ;
  end
endmodule
