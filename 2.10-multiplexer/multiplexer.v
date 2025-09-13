module multiplexer(x1, x2, s, f);
  input x1, x2, s;
  output f;

  wire g, h, k;

  not(k, s);
  and(g, k, x1);
  and(h, s, x2);
  or(f, g, h);

endmodule
