module sine_cosine (
    clock,
    angle,
    Xin,
    Yin,
    Xout,
    Yout
);

  parameter c_parameter = 16;  // bit width of input and output data

  localparam STG = c_parameter;  // similar bit width of vectors X and Y

  input clock;

  input signed [31:0] angle;
  input signed [c_parameter -1:0] Xin;
  input signed [c_parameter -1:0] Yin;
  output signed [c_parameter : 0] Xout;
  output signed [c_parameter : 0] Yout;

  //arctan_table

  // Note: The atan_table was chosen to be 31 bits wide giving resolution up to atan(2^-30)
  wire signed [31:0] atan_table[0:30];

  // upper 2 bits = 2'b00 which represents 0 - PI/2 range
  // upper 2 bits = 2'b01 which represents PI/2 to PI range
  // upper 2 bits = 2'b10 which represents PI to 3*PI/2 range (i.e. -PI/2 to -PI)
  // upper 2 bits = 2'b11 which represents 3*PI/2 to 2*PI range (i.e. 0 to -PI/2)
  // The upper 2 bits therefore tell us which quadrant we are in.
  assign atan_table[00] = 32'b00100000000000000000000000000000;  // 45.000 degrees -> atan(2^0)
  assign atan_table[01] = 32'b00010010111001000000010100011101;  // 26.565 degrees -> atan(2^-1)
  assign atan_table[02] = 32'b00001001111110110011100001011011;  // 14.036 degrees -> atan(2^-2)
  assign atan_table[03] = 32'b00000101000100010001000111010100;  // atan(2^-3)
  assign atan_table[04] = 32'b00000010100010110000110101000011;
  assign atan_table[05] = 32'b00000001010001011101011111100001;
  assign atan_table[06] = 32'b00000000101000101111011000011110;
  assign atan_table[07] = 32'b00000000010100010111110001010101;
  assign atan_table[08] = 32'b00000000001010001011111001010011;
  assign atan_table[09] = 32'b00000000000101000101111100101110;
  assign atan_table[10] = 32'b00000000000010100010111110011000;
  assign atan_table[11] = 32'b00000000000001010001011111001100;
  assign atan_table[12] = 32'b00000000000000101000101111100110;
  assign atan_table[13] = 32'b00000000000000010100010111110011;
  assign atan_table[14] = 32'b00000000000000001010001011111001;
  assign atan_table[15] = 32'b00000000000000000101000101111101;
  assign atan_table[16] = 32'b00000000000000000010100010111110;
  assign atan_table[17] = 32'b00000000000000000001010001011111;
  assign atan_table[18] = 32'b00000000000000000000101000101111;
  assign atan_table[19] = 32'b00000000000000000000010100011000;
  assign atan_table[20] = 32'b00000000000000000000001010001100;
  assign atan_table[21] = 32'b00000000000000000000000101000110;
  assign atan_table[22] = 32'b00000000000000000000000010100011;
  assign atan_table[23] = 32'b00000000000000000000000001010001;
  assign atan_table[24] = 32'b00000000000000000000000000101000;
  assign atan_table[25] = 32'b00000000000000000000000000010100;
  assign atan_table[26] = 32'b00000000000000000000000000001010;
  assign atan_table[27] = 32'b00000000000000000000000000000101;
  assign atan_table[28] = 32'b00000000000000000000000000000010;
  assign atan_table[29] = 32'b00000000000000000000000000000001;  // atan(2^-29)
  assign atan_table[30] = 32'b00000000000000000000000000000000;

  //------------------------------------------------------------------------------
  //                              registers
  //------------------------------------------------------------------------------

  //stage outputs
  reg signed [c_parameter : 0] X        [0:STG-1];
  reg signed [c_parameter : 0] Y        [0:STG-1];
  reg signed [           31:0] Z        [0:STG-1];  // 32bit

  //------------------------------------------------------------------------------
  //                               stage 0
  //------------------------------------------------------------------------------
  wire       [            1:0] quadrant;
  assign quadrant = angle[31:30];

  always @(posedge clock)
   begin // make sure the rotation angle is in the -pi/2 to pi/2 range.  If not then pre-rotate
    case (quadrant)
      2'b00,
         2'b11:   // no pre-rotation needed for these quadrants
         begin    // X[n], Y[n] is 1 bit larger than Xin, Yin, but Verilog handles the assignments properly
        X[0] <= Xin;
        Y[0] <= Yin;
        Z[0] <= angle;
      end

      2'b01: begin
        X[0] <= -Yin;
        Y[0] <= Xin;
        Z[0] <= {2'b00, angle[29:0]};  // subtract pi/2 from angle for this quadrant
      end

      2'b10: begin
        X[0] <= Yin;
        Y[0] <= -Xin;
        Z[0] <= {2'b11, angle[29:0]};  // add pi/2 to angle for this quadrant
      end

    endcase
  end

  //------------------------------------------------------------------------------
  //                           generate stages 1 to STG-1
  //------------------------------------------------------------------------------
  // genvar i;
  //
  // generate
  //   for (i = 0; i < (STG - 1); i = i + 1) begin : XYZ
  //     wire Z_sign;
  //     wire signed [c_parameter : 0] X_shr, Y_shr;
  //
  //     assign X_shr  = X[i] >>> i;  // signed shift right
  //     assign Y_shr  = Y[i] >>> i;
  //
  //     //the sign of the current rotation angle
  //     assign Z_sign = Z[i][31];  // Z_sign = 1 if Z[i] < 0
  //
  //     always @(posedge clock) begin
  //       // add/subtract shifted data
  //       X[i+1] <= Z_sign ? X[i] + Y_shr : X[i] - Y_shr;
  //       Y[i+1] <= Z_sign ? Y[i] - X_shr : Y[i] + X_shr;
  //       Z[i+1] <= Z_sign ? Z[i] + atan_table[i] : Z[i] - atan_table[i];
  //     end
  //   end
  // endgenerate

  wire Z_sign_0;
  wire signed [c_parameter : 0] X_shr_0, Y_shr_0;

  assign X_shr_0  = X[0] >>> 0;  // signed shift right
  assign Y_shr_0  = Y[0] >>> 0;

  //the sign of the current rotation angle
  assign Z_sign_0 = Z[0][31];  // Z_sign = 1 if Z[0] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[0+1] <= Z_sign_0 ? X[0] + Y_shr_0 : X[0] - Y_shr_0;
    Y[0+1] <= Z_sign_0 ? Y[0] - X_shr_0 : Y[0] + X_shr_0;
    Z[0+1] <= Z_sign_0 ? Z[0] + atan_table[0] : Z[0] - atan_table[0];
  end
  wire Z_sign_1;
  wire signed [c_parameter : 0] X_shr_1, Y_shr_1;

  assign X_shr_1  = X[1] >>> 1;  // signed shift right
  assign Y_shr_1  = Y[1] >>> 1;

  //the sign of the current rotation angle
  assign Z_sign_1 = Z[1][31];  // Z_sign = 1 if Z[1] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[1+1] <= Z_sign_1 ? X[1] + Y_shr_1 : X[1] - Y_shr_1;
    Y[1+1] <= Z_sign_1 ? Y[1] - X_shr_1 : Y[1] + X_shr_1;
    Z[1+1] <= Z_sign_1 ? Z[1] + atan_table[1] : Z[1] - atan_table[1];
  end
  wire Z_sign_2;
  wire signed [c_parameter : 0] X_shr_2, Y_shr_2;

  assign X_shr_2  = X[2] >>> 2;  // signed shift right
  assign Y_shr_2  = Y[2] >>> 2;

  //the sign of the current rotation angle
  assign Z_sign_2 = Z[2][31];  // Z_sign = 1 if Z[2] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[2+1] <= Z_sign_2 ? X[2] + Y_shr_2 : X[2] - Y_shr_2;
    Y[2+1] <= Z_sign_2 ? Y[2] - X_shr_2 : Y[2] + X_shr_2;
    Z[2+1] <= Z_sign_2 ? Z[2] + atan_table[2] : Z[2] - atan_table[2];
  end
  wire Z_sign_3;
  wire signed [c_parameter : 0] X_shr_3, Y_shr_3;

  assign X_shr_3  = X[3] >>> 3;  // signed shift right
  assign Y_shr_3  = Y[3] >>> 3;

  //the sign of the current rotation angle
  assign Z_sign_3 = Z[3][31];  // Z_sign = 1 if Z[3] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[3+1] <= Z_sign_3 ? X[3] + Y_shr_3 : X[3] - Y_shr_3;
    Y[3+1] <= Z_sign_3 ? Y[3] - X_shr_3 : Y[3] + X_shr_3;
    Z[3+1] <= Z_sign_3 ? Z[3] + atan_table[3] : Z[3] - atan_table[3];
  end
  wire Z_sign_4;
  wire signed [c_parameter : 0] X_shr_4, Y_shr_4;

  assign X_shr_4  = X[4] >>> 4;  // signed shift right
  assign Y_shr_4  = Y[4] >>> 4;

  //the sign of the current rotation angle
  assign Z_sign_4 = Z[4][31];  // Z_sign = 1 if Z[4] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[4+1] <= Z_sign_4 ? X[4] + Y_shr_4 : X[4] - Y_shr_4;
    Y[4+1] <= Z_sign_4 ? Y[4] - X_shr_4 : Y[4] + X_shr_4;
    Z[4+1] <= Z_sign_4 ? Z[4] + atan_table[4] : Z[4] - atan_table[4];
  end
  wire Z_sign_5;
  wire signed [c_parameter : 0] X_shr_5, Y_shr_5;

  assign X_shr_5  = X[5] >>> 5;  // signed shift right
  assign Y_shr_5  = Y[5] >>> 5;

  //the sign of the current rotation angle
  assign Z_sign_5 = Z[5][31];  // Z_sign = 1 if Z[5] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[5+1] <= Z_sign_5 ? X[5] + Y_shr_5 : X[5] - Y_shr_5;
    Y[5+1] <= Z_sign_5 ? Y[5] - X_shr_5 : Y[5] + X_shr_5;
    Z[5+1] <= Z_sign_5 ? Z[5] + atan_table[5] : Z[5] - atan_table[5];
  end
  wire Z_sign_6;
  wire signed [c_parameter : 0] X_shr_6, Y_shr_6;

  assign X_shr_6  = X[6] >>> 6;  // signed shift right
  assign Y_shr_6  = Y[6] >>> 6;

  //the sign of the current rotation angle
  assign Z_sign_6 = Z[6][31];  // Z_sign = 1 if Z[6] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[6+1] <= Z_sign_6 ? X[6] + Y_shr_6 : X[6] - Y_shr_6;
    Y[6+1] <= Z_sign_6 ? Y[6] - X_shr_6 : Y[6] + X_shr_6;
    Z[6+1] <= Z_sign_6 ? Z[6] + atan_table[6] : Z[6] - atan_table[6];
  end
  wire Z_sign_7;
  wire signed [c_parameter : 0] X_shr_7, Y_shr_7;

  assign X_shr_7  = X[7] >>> 7;  // signed shift right
  assign Y_shr_7  = Y[7] >>> 7;

  //the sign of the current rotation angle
  assign Z_sign_7 = Z[7][31];  // Z_sign = 1 if Z[7] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[7+1] <= Z_sign_7 ? X[7] + Y_shr_7 : X[7] - Y_shr_7;
    Y[7+1] <= Z_sign_7 ? Y[7] - X_shr_7 : Y[7] + X_shr_7;
    Z[7+1] <= Z_sign_7 ? Z[7] + atan_table[7] : Z[7] - atan_table[7];
  end
  wire Z_sign_8;
  wire signed [c_parameter : 0] X_shr_8, Y_shr_8;

  assign X_shr_8  = X[8] >>> 8;  // signed shift right
  assign Y_shr_8  = Y[8] >>> 8;

  //the sign of the current rotation angle
  assign Z_sign_8 = Z[8][31];  // Z_sign = 1 if Z[8] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[8+1] <= Z_sign_8 ? X[8] + Y_shr_8 : X[8] - Y_shr_8;
    Y[8+1] <= Z_sign_8 ? Y[8] - X_shr_8 : Y[8] + X_shr_8;
    Z[8+1] <= Z_sign_8 ? Z[8] + atan_table[8] : Z[8] - atan_table[8];
  end
  wire Z_sign_9;
  wire signed [c_parameter : 0] X_shr_9, Y_shr_9;

  assign X_shr_9  = X[9] >>> 9;  // signed shift right
  assign Y_shr_9  = Y[9] >>> 9;

  //the sign of the current rotation angle
  assign Z_sign_9 = Z[9][31];  // Z_sign = 1 if Z[9] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[9+1] <= Z_sign_9 ? X[9] + Y_shr_9 : X[9] - Y_shr_9;
    Y[9+1] <= Z_sign_9 ? Y[9] - X_shr_9 : Y[9] + X_shr_9;
    Z[9+1] <= Z_sign_9 ? Z[9] + atan_table[9] : Z[9] - atan_table[9];
  end
  wire Z_sign_10;
  wire signed [c_parameter : 0] X_shr_10, Y_shr_10;

  assign X_shr_10  = X[10] >>> 10;  // signed shift right
  assign Y_shr_10  = Y[10] >>> 10;

  //the sign of the current rotation angle
  assign Z_sign_10 = Z[10][31];  // Z_sign = 1 if Z[10] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[10+1] <= Z_sign_10 ? X[10] + Y_shr_10 : X[10] - Y_shr_10;
    Y[10+1] <= Z_sign_10 ? Y[10] - X_shr_10 : Y[10] + X_shr_10;
    Z[10+1] <= Z_sign_10 ? Z[10] + atan_table[10] : Z[10] - atan_table[10];
  end
  wire Z_sign_11;
  wire signed [c_parameter : 0] X_shr_11, Y_shr_11;

  assign X_shr_11  = X[11] >>> 11;  // signed shift right
  assign Y_shr_11  = Y[11] >>> 11;

  //the sign of the current rotation angle
  assign Z_sign_11 = Z[11][31];  // Z_sign = 1 if Z[11] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[11+1] <= Z_sign_11 ? X[11] + Y_shr_11 : X[11] - Y_shr_11;
    Y[11+1] <= Z_sign_11 ? Y[11] - X_shr_11 : Y[11] + X_shr_11;
    Z[11+1] <= Z_sign_11 ? Z[11] + atan_table[11] : Z[11] - atan_table[11];
  end
  wire Z_sign_12;
  wire signed [c_parameter : 0] X_shr_12, Y_shr_12;

  assign X_shr_12  = X[12] >>> 12;  // signed shift right
  assign Y_shr_12  = Y[12] >>> 12;

  //the sign of the current rotation angle
  assign Z_sign_12 = Z[12][31];  // Z_sign = 1 if Z[12] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[12+1] <= Z_sign_12 ? X[12] + Y_shr_12 : X[12] - Y_shr_12;
    Y[12+1] <= Z_sign_12 ? Y[12] - X_shr_12 : Y[12] + X_shr_12;
    Z[12+1] <= Z_sign_12 ? Z[12] + atan_table[12] : Z[12] - atan_table[12];
  end
  wire Z_sign_13;
  wire signed [c_parameter : 0] X_shr_13, Y_shr_13;

  assign X_shr_13  = X[13] >>> 13;  // signed shift right
  assign Y_shr_13  = Y[13] >>> 13;

  //the sign of the current rotation angle
  assign Z_sign_13 = Z[13][31];  // Z_sign = 1 if Z[13] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[13+1] <= Z_sign_13 ? X[13] + Y_shr_13 : X[13] - Y_shr_13;
    Y[13+1] <= Z_sign_13 ? Y[13] - X_shr_13 : Y[13] + X_shr_13;
    Z[13+1] <= Z_sign_13 ? Z[13] + atan_table[13] : Z[13] - atan_table[13];
  end
  wire Z_sign_14;
  wire signed [c_parameter : 0] X_shr_14, Y_shr_14;

  assign X_shr_14  = X[14] >>> 14;  // signed shift right
  assign Y_shr_14  = Y[14] >>> 14;

  //the sign of the current rotation angle
  assign Z_sign_14 = Z[14][31];  // Z_sign = 1 if Z[14] < 0

  always @(posedge clock) begin
    // add/subtract shifted data
    X[14+1] <= Z_sign_14 ? X[14] + Y_shr_14 : X[14] - Y_shr_14;
    Y[14+1] <= Z_sign_14 ? Y[14] - X_shr_14 : Y[14] + X_shr_14;
    Z[14+1] <= Z_sign_14 ? Z[14] + atan_table[14] : Z[14] - atan_table[14];
  end

  //------------------------------------------------------------------------------
  //                                 output
  //------------------------------------------------------------------------------
  assign Xout = X[STG-1];
  assign Yout = Y[STG-1];

endmodule
