`timescale 1ns / 100ps

module cordic_tb;

  parameter N = 10;  // number of iterations

  reg [10:0] z0;
  wire [16:0] xn, yn;
  wire [10:0] zn;

  // file operators
  integer I_out, Q_out, Z_out;

  cordic C1 (
      .z0(z0),
      .xn(xn),
      .yn(yn),
      .zn(zn)
  );

  initial begin
    $dumpfile("cordic.vcd");
    $dumpvars(0, cordic_tb);

    I_out = $fopen("cos_out.txt", "w");  // Output file for debugging
    Q_out = $fopen("sin_out.txt", "w");  // Output file for debugging
    Z_out = $fopen("angle_out.txt", "w");  // Output file for debugging

    // z0 = 11'b010_1101_0000; // 45 degrees
    z0 = 11'b001_0100_0000;  // 20 degrees
    #100 $fclose(I_out);
    $fclose(Q_out);
    $fclose(Z_out);

    #10 $finish;
  end

  always @(xn, yn, zn) begin
    $fwrite(I_out, "%.17f\n", xn / 131072.0);
    $fwrite(Q_out, "%.17f\n", yn / 131072.0);
    $fwrite(Z_out, "%.17f\n", zn / 131072.0);
  end

endmodule
