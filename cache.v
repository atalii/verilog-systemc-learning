module cache #(
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2
)(
    input wire clock,

    input wire [ADDR_WIDTH - 1:0] ch1_in_addr,
    input wire [LINE_WIDTH - 1:0] ch1_in_val,
    input wire ch1_read,
    input wire ch1_write,
    output reg ch1_hit,
    output reg [LINE_WIDTH - 1:0] ch1_out_val,

    input wire [ADDR_WIDTH - 1:0] ch2_in_addr,
    input wire ch2_read,
    output reg ch2_hit,
    output reg [LINE_WIDTH - 1:0] ch2_out_val
);
  reg [LINE_WIDTH - 1:0] vals[K];
  reg [ADDR_WIDTH - 1:0] addrs[K];
  reg valid_bits[K];
  reg clock_counts[K];
  reg [$clog2(K) - 1:0] clock_ptr = 0;

  reg write_state = 0;

  reg accumulator;

  function automatic check_for_hit(integer ch);
    accumulator = 0;

    for (integer i = 0; i < K; i++) begin
      accumulator = accumulator || (addrs[i] ==
        (ch == 1 ? ch1_in_addr : ch2_in_addr) && valid_bits[i]);
    end
    check_for_hit = accumulator;
  endfunction

  always @(posedge clock) begin
    if (ch1_read) begin
      integer i;
      for (i = 0; i < K; i++) begin
        if (addrs[i] == ch1_in_addr && valid_bits[i]) begin
          ch1_out_val <= vals[i];
          clock_counts[i] <= 1;
        end
      end

      ch1_hit <= check_for_hit(1);
    end

    if (ch2_read) begin
      for (integer i = 0; i < K; i++) begin
        if (addrs[i] == ch2_in_addr && valid_bits[i]) begin
          ch2_out_val <= vals[i];
          clock_counts[i] <= 1;
        end
      end

      ch2_hit <= check_for_hit(2);
    end
  end

  always @(posedge clock) begin
    if (ch1_write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        integer i;
        for (i = 0; i < K; i++) begin
          if (addrs[i] == ch1_in_addr) begin
            vals[i] <= ch1_in_val;
            clock_counts[i] <= 1;
            valid_bits[i] = 1;
          end
        end

        ch1_hit <= check_for_hit(1);

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= !check_for_hit(1);
      end

      1: begin
        // CLOCK through the two values.
        clock_ptr <= clock_ptr + 1;

        if (clock_counts[clock_ptr] == 0) begin
          // Evict what we're looking at.
          addrs[clock_ptr] <= ch1_in_addr;
          vals[clock_ptr] <= ch1_in_val;
          clock_counts[clock_ptr] <= 1;
          valid_bits[clock_ptr] = 1;
          ch1_hit <= 1;
          write_state <= 0;
        end else clock_counts[clock_ptr] <= 0; // Decrement the CLOCK counter.
      end

      endcase
    end
  end
endmodule
