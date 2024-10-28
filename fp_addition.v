module fp_add (
    input [31:0] a,    // First 32-bit floating-point number
    input [31:0] b,    // Second 32-bit floating-point number
    output [31:0] result  // Result of the addition
);

    wire sign_a, sign_b;
    wire [7:0] exponent_a, exponent_b;
    wire [23:0] mantissa_a, mantissa_b;
    wire [23:0] aligned_mantissa_a, aligned_mantissa_b;
    wire [7:0] exponent_diff;
    wire [7:0] exponent_result;
    wire sign_result;
    wire [24:0] mantissa_sum;
    wire [23:0] mantissa_final;
    wire [7:0] exponent_adjusted;
    wire carry;

    // Extract sign, exponent, and mantissa
    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exponent_a = a[30:23];
    assign exponent_b = b[30:23];
    assign mantissa_a = (exponent_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]}; // Handle denormals
    assign mantissa_b = (exponent_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]}; // Handle denormals

    // Align exponents by shifting the mantissa of the smaller exponent
    assign exponent_diff = (exponent_a > exponent_b) ? (exponent_a - exponent_b) : (exponent_b - exponent_a);
    assign aligned_mantissa_a = (exponent_a > exponent_b) ? mantissa_a : (mantissa_a >> exponent_diff);
    assign aligned_mantissa_b = (exponent_b > exponent_a) ? mantissa_b : (mantissa_b >> exponent_diff);
    assign exponent_result = (exponent_a > exponent_b) ? exponent_a : exponent_b;

    // Add or subtract mantissas based on sign
    assign mantissa_sum = (sign_a == sign_b) ? ({1'b0, aligned_mantissa_a} + {1'b0, aligned_mantissa_b}) :
                                                      (aligned_mantissa_a >= aligned_mantissa_b) ? ({1'b0, aligned_mantissa_a} - {1'b0, aligned_mantissa_b}) :
                                                                                                  ({1'b0, aligned_mantissa_b} - {1'b0, aligned_mantissa_a});
    assign sign_result = (aligned_mantissa_a >= aligned_mantissa_b) ? sign_a : sign_b;

    // Normalize the result mantissa
    assign mantissa_final = mantissa_sum[24] ? mantissa_sum[24:1]: mantissa_sum[23:0];
    assign exponent_adjusted = mantissa_sum[24] ? exponent_result + 1 : exponent_result;

    // Handle special cases (NaN, infinity, zero)
    wire a_is_zero = (exponent_a == 8'd0 && a[22:0] == 23'd0);
    wire b_is_zero = (exponent_b == 8'd0 && b[22:0] == 23'd0);
    wire a_is_inf = (exponent_a == 8'd255 && a[22:0] == 23'd0);
    wire b_is_inf = (exponent_b == 8'd255 && b[22:0] == 23'd0);
    wire a_is_nan = (exponent_a == 8'd255 && a[22:0] != 23'd0);
    wire b_is_nan = (exponent_b == 8'd255 && b[22:0] != 23'd0);

    assign result = a_is_nan ? a :
                    b_is_nan ? b :
                    (a_is_inf & b_is_inf & (sign_a != sign_b)) ? 32'hFFC00000 : // NaN
                    a_is_inf ? a :
                    b_is_inf ? b :
                    a_is_zero ? b :
                    b_is_zero ? a :
                    {sign_result, exponent_adjusted[7:0], mantissa_final[22:0]};

endmodule
