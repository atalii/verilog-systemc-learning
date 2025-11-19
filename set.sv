module set #(
  parameter integer ADDR_WIDTH = 8,
  parameter integer LINE_WIDTH = 32,
  parameter integer K = 2
)(
    input wire enable,
    input wire clock,
    input wire [ADDR_WIDTH - 1:0] in_addr,
    input wire [LINE_WIDTH - 1:0] in_val,
    input wire read,
    input wire write,
    output reg hit,
    output reg [LINE_WIDTH - 1:0] out_val
);
  typedef bit [ADDR_WIDTH - 1:0] addr_t;
  typedef bit [LINE_WIDTH - 1:0] val_t;

  typedef enum {
    ST_INVALID, ST_VALID
  } state_t;

  typedef struct packed {
    val_t val;
    addr_t addr;
    bit clock;
    state_t state;
  } line_t;

  line_t lines[K];
  reg [$clog2(K) - 1:0] clock_ptr = 0;

  reg write_state = 0;

  reg accumulator;

  function automatic check_for_hit();
    accumulator = 0;

    for (integer i = 0; i < K; i++) begin
      accumulator |= lines[i].addr == in_addr && lines[i].state == ST_VALID;
    end
    check_for_hit = accumulator;
  endfunction

  task automatic run_read(input addr_t addr);
    if (read) begin
      for (integer i = 0; i < K; i++) begin
        if (lines[i].addr == addr && lines[i].state == ST_VALID) begin
          out_val <= lines[i].val;
        end
      end

      hit <= check_for_hit();
    end
  endtask

  always @(posedge clock) begin
    if (enable)
      run_read(in_addr);
  end

  always @(posedge clock) begin
    if (enable && write) begin
      // We'll match on where we are in the state machine.
      unique case (write_state)
      0: begin
        // If we're just receiving the write request, look for any matches.
        for (integer i = 0; i < K; i++) begin
          if (lines[i].addr == in_addr) begin
            lines[i].val <= in_val;
            lines[i].clock <= 1;
            lines[i].state <= ST_VALID;
          end
        end

        hit <= check_for_hit();

        // Set the write_state high iff we haven't hit anything in the cache.
        write_state <= !check_for_hit();
      end

      1: begin
        // CLOCK through the two values.
        clock_ptr <= clock_ptr + 1;

        for (integer i = 0; i < K; i++) begin
          if (i == integer'(clock_ptr)) begin
            if (lines[i].clock == 0) begin
              // Evict what we're looking at.
              lines[i].addr <= in_addr;
              lines[i].val <= in_val;
              lines[i].state <= ST_VALID;
              lines[i].clock <= 1;

              hit <= 1;
              write_state <= 0;
            end else lines[i].clock <= 0; // Decrement the CLOCK counter.
          end;
        end
      end

      endcase
    end
  end
endmodule
