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

  reg [LINE_WIDTH - 1:0] vals[2];
  reg [ADDR_WIDTH - 1:0] addrs[2];
  reg clock_counts[2];
  reg clock_ptr = 0;

  reg write_state = 0;

  always @(posedge clock) begin
    if (read) begin
      hit <= (addrs[0] == in_addr) | (addrs[1] == in_addr);
      out_val <= (addrs[0] == in_addr) ? vals[0] : vals[1];

      clock_counts[0] <= addrs[0] == in_addr ? 1 : clock_counts[0];
      clock_counts[1] <= addrs[1] == in_addr ? 1 : clock_counts[1];
    end
  end

  always @(posedge clock) begin
    if (write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        vals[0] <= (addrs[0] == in_addr) ? in_val : vals[0];
        vals[1] <= (addrs[1] == in_addr) ? in_val : vals[1];
        clock_counts[0] <= (addrs[0] == in_addr) ? 1 : clock_counts[0];
        clock_counts[1] <= (addrs[1] == in_addr) ? 1 : clock_counts[1];
        hit <= (addrs[0] == in_addr) | (addrs[1] == in_addr);

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= (addrs[0] != in_addr) & (addrs[1] != in_addr);
      end

      1: begin
        // CLOCK through the two values.
        clock_ptr <= !clock_ptr;

        if (clock_counts[clock_ptr] == 0) begin
          // Evict what we're looking at.
          addrs[0] <= clock_ptr ? addrs[0] : in_addr;
          addrs[1] <= clock_ptr ? in_addr : addrs[1];
          vals[0] <= clock_ptr ? vals[0] : in_val;
          vals[1] <= clock_ptr ? in_val : vals[1];
          clock_counts[0] <= clock_ptr ? 1 : clock_counts[0];
          clock_counts[1] <= clock_ptr ? clock_counts[1] : 1;
          hit <= 1;
          write_state <= 0;
        end else begin
          // Decrement the CLOCK counter.
          clock_counts[0] <= clock_ptr ? clock_counts[0] : 0;
          clock_counts[1] <= clock_ptr ? 0 : clock_counts[1];
        end
      end

      endcase
    end
  end
endmodule
