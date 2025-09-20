module cache (
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

  reg [31:0] val_a, val_b;
  reg [7:0] addr_a, addr_b;
  reg clock_count_a, clock_count_b;

  reg write_state = 0;

  always @(posedge clock) begin
    if (read) begin
      hit <= (addr_a == in_addr) | (addr_b == in_addr);
      out_val <= (addr_a == in_addr) ? val_a : val_b;
    end
  end

  always @(posedge clock) begin
    if (write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        val_a <= (addr_a == in_addr) ? in_val : val_a;
        val_b <= (addr_b == in_addr) ? in_val : val_b;
        hit <= (addr_a == in_addr) | (addr_b == in_addr);

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= (addr_a != in_addr) & (addr_b != in_addr);
      end

      1: begin
        // TODO: start CLOCKing through the cache.
        write_state <= 0;
        hit <= 1;
      end

      endcase
    end
  end
endmodule
