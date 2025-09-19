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

  reg a_write, a_hit, b_write, b_hit;
  reg [31:0] a_out_val, b_out_val;

  // Store which register we'll try to write to first.
  reg which_write;
  // Store whether or not we're currently attempting to write.
  reg writing;

  cacheline a (
      .in_addr(in_addr),
      .in_val(in_val),
      .read(read),
      .write(a_write),
      .clock(clock),
      .hit(a_hit),
      .out_val(a_out_val)
  );

  cacheline b (
      .in_addr(in_addr),
      .in_val(in_val),
      .read(read),
      .write(b_write),
      .clock(clock),
      .hit(b_hit),
      .out_val(b_out_val)
  );

  always @(posedge clock) begin
    if (read) begin
      hit <= a_hit | b_hit;
      out_val <= a_hit ? a_out_val : b_out_val;
    end
  end

  always @(posedge clock) begin
    if (write & !writing) begin
      // Start the write process.
      a_write <= !which_write;
      b_write <= which_write;
      hit <= 0;
      writing <= 1;
    end
  end

  always @(posedge clock) begin
    if (write & writing) begin
      // Continue the write process. This means that we check for a hit, and,
      // if we failed, look at the next line.
      a_write <= !(a_hit | b_hit) & !a_write;
      b_write <= !(a_hit | b_hit) & !b_write;
      writing <= !(a_hit | b_hit);
      hit <= a_hit | b_hit;
    end
  end

endmodule
