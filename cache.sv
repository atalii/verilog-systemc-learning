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
  typedef struct packed {
    bit [LINE_WIDTH - 1:0] val;
    bit [ADDR_WIDTH - 1:0] addr;
    bit clock;
    bit valid;
  } line_t;

  line_t lines[K];
  reg [$clog2(K) - 1:0] clock_ptr = 0;

  reg write_state = 0;

  reg accumulator;

  function automatic check_for_hit(integer ch);
    accumulator = 0;

    for (integer i = 0; i < K; i++) begin
      accumulator = accumulator || (lines[i].addr ==
        (ch == 1 ? ch1_in_addr : ch2_in_addr) && lines[i].valid);
    end
    check_for_hit = accumulator;
  endfunction

  task automatic read (input [ADDR_WIDTH - 1:0] addr, input integer channel);
    if (channel == 1 && ch1_read || (channel == 2 && ch2_read)) begin
      for (integer i = 0; i < K; i++) begin
        if (lines[i].addr == addr && lines[i].valid) begin
          if (channel == 1) ch1_out_val <= lines[i].val;
          else if (channel == 2) ch2_out_val <= lines[i].val;
        end
      end

      if (channel == 1) ch1_hit <= check_for_hit(channel);
      if (channel == 2) ch2_hit <= check_for_hit(channel);
    end
  endtask

  always @(posedge clock) begin
    read(ch1_in_addr, 1);
    read(ch2_in_addr, 2);
  end

  always @(posedge clock) begin
    if (ch1_write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        integer i;
        for (i = 0; i < K; i++) begin
          if (lines[i].addr == ch1_in_addr) begin
            lines[i].val <= ch1_in_val;
            lines[i].clock <= 1;
            lines[i].valid <= 1;
          end
        end

        ch1_hit <= check_for_hit(1);

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= !check_for_hit(1);
      end

      1: begin
        // CLOCK through the two values.
        clock_ptr <= clock_ptr + 1;

        for (integer i = 0; i < K; i++) begin
          if (i == integer'(clock_ptr)) begin
            if (lines[i].clock == 0) begin
              // Evict what we're looking at.
              lines[i].addr <= ch1_in_addr;
              lines[i].val <= ch1_in_val;
              lines[i].valid <= 1;
              lines[i].clock <= 1;

              ch1_hit <= 1;
              write_state <= 0;
            end else lines[i].clock <= 0; // Decrement the CLOCK counter.
          end;
        end
      end

      endcase
    end
  end
endmodule
