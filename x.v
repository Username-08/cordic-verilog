`timescale 1ns / 100ps
`define OPT_SIMULATE =1

module cordic (
    z0,
    xn,
    yn,
    zn
);

  input [10:0] z0;
  output reg [16:0] xn, yn;
  output reg [10:0] zn;

  parameter N = 10;  // number of iterations

  reg [(N-1):0] d;
  reg [16:0] x[(N-1):0];
  reg [16:0] y[(N-1):0];
  reg [10:0] z[(N-1):0];

  wire [10:0] arctan[(N-1):0];


  assign arctan[0] = 'b010_1101_0000;  // 45.0;
  assign arctan[1] = 'b001_1010_1001;  // 26.6;
  assign arctan[2] = 'b000_1110_0000;  // 14.0;
  assign arctan[3] = 'b000_0111_0001;  // 7.1;
  assign arctan[4] = 'b000_0011_1001;  // 3.6;
  assign arctan[5] = 'b000_0001_1100;  // 1.8;
  assign arctan[6] = 'b000_0000_1110;  // 0.9;
  assign arctan[7] = 'b000_0000_0110;  // 0.4;
  assign arctan[8] = 'b000_0000_0011;  // 0.2;
  assign arctan[9] = 'b000_0000_0001;  // 0.1;

  integer i;

  always @(*) begin
    x[0] = 'b0_10011_0110_1110_1001;  // 0.60725 in binary
    y[0] = 0;
    z[0] = z0;

    for (i = 0; i < N; i = i + 1) begin
      d[i] = (z[i][10] == 0) ? 0 : 1;

      if (d[i] == 0) begin
        x[i+1] = x[i] - (y[i] >> i);
        y[i+1] = y[i] + (x[i] >> i);
        z[i+1] = z[i] - arctan[i];
      end else begin
        x[i+1] = x[i] + (y[i] >> i);
        y[i+1] = y[i] - (x[i] >> i);
        z[i+1] = z[i] + arctan[i];
      end

      xn = x[i];  // xn = cos(z0)
      yn = y[i];  // yn = sin(z0)
      zn = z[i];

`ifdef OPT_SIMULATE
      $display("i=%2d, x[i]=%b, y[i]=%b, z[i]=%b, d[i]=%2d, arctan[i]=%b", i, x[i], y[i], z[i],
               d[i], arctan[i]);
      #1;
`endif
    end
  end

endmodule
