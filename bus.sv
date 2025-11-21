module bus #(
    parameter integer WIDTH = 2,
    parameter integer CLIENTS = 4
)(
    input wire clock,
    input logic [WIDTH - 1:0] messages[CLIENTS],
    input logic write[CLIENTS],
    output logic [WIDTH - 1:0] message,
    output logic sent[CLIENTS]
);
  reg [$clog2(CLIENTS) - 1:0] rr;

  always @(posedge clock) begin
    if (write[rr]) begin
        message <= messages[rr];
    end

    for (int i = 0; i < CLIENTS; i++) begin
        sent[i] <= i == integer'(rr) && write[rr];
    end

    rr <= rr + 1;
  end
endmodule
