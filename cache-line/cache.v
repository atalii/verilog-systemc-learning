module cache (
    in_addr,
    in_val,
    read,
    write,
    clock,
    hit,
    out_val
);
  parameter integer ADDR_WIDTH = 8;
  parameter integer LINE_WIDTH = 32;

  input reg [ADDR_WIDTH - 1:0] in_addr;
  input reg [LINE_WIDTH - 1:0] in_val;
  input wire read, write, clock;

  output reg [LINE_WIDTH - 1:0] out_val;
  output reg hit;

  reg [LINE_WIDTH - 1:0] val_a, val_b;
  reg [ADDR_WIDTH - 1:0] addr_a, addr_b;
  reg clock_count_a = 0, clock_count_b = 0;
  reg clock_ptr = 0;

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
        // CLOCK through the two values.
        clock_ptr <= !clock_ptr;

        if ((clock_ptr ? clock_count_a : clock_count_b) == 0) begin
          addr_a <= clock_ptr ? in_addr : addr_a;
          addr_b <= clock_ptr ? addr_b : in_addr;
          val_a <= clock_ptr ? in_val : val_a;
          val_b <= clock_ptr ? val_b : in_val;
          hit <= 1;
          write_state <= 0;
        end
      end

      endcase
    end
  end
endmodule
