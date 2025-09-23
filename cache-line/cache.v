module cache #(
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2
)(
    input reg [ADDR_WIDTH - 1:0] in_addr,
    input reg [LINE_WIDTH - 1:0] in_val,
    input wire read,
    input wire write,
    input wire clock,
    output reg hit,
    output reg [LINE_WIDTH - 1:0] out_val
);
  reg [LINE_WIDTH - 1:0] vals[K];
  reg [ADDR_WIDTH - 1:0] addrs[K];
  reg clock_counts[K];
  reg [$clog2(K) - 1:0] clock_ptr = 0;

  reg write_state = 0;

  reg accumulator;

  function automatic check_for_hit();
    accumulator = 0;

    for (integer i = 0; i < K; i++) begin
      accumulator = accumulator || (addrs[i] == in_addr);
    end
    check_for_hit = accumulator;
  endfunction

  always @(posedge clock) begin
    if (read) begin
      integer i;
      for (i = 0; i < K; i++) begin
        if (addrs[i] == in_addr) begin
          out_val <= vals[i];
          clock_counts[i] <= 1;
        end
      end

      hit <= check_for_hit();
    end
  end

  always @(posedge clock) begin
    if (write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        integer i;
        for (i = 0; i < K; i++) begin
          if (addrs[i] == in_addr) begin
            vals[i] <= in_val;
            clock_counts[i] <= 1;
          end
        end

        hit <= check_for_hit();

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= !check_for_hit();
      end

      1: begin
        // CLOCK through the two values.
        clock_ptr <= clock_ptr + 1;

        if (clock_counts[clock_ptr] == 0) begin
          // Evict what we're looking at.
          addrs[clock_ptr] <= in_addr;
          vals[clock_ptr] <= in_val;
          clock_counts[clock_ptr] <= 1;
          hit <= 1;
          write_state <= 0;
        end else clock_counts[clock_ptr] <= 0; // Decrement the CLOCK counter.
      end

      endcase
    end
  end
endmodule
