module fp_mul (
    input [31:0] a,    // First 32-bit floating-point number
    input [31:0] b,    // Second 32-bit floating-point number
    output [31:0] result  // Result of the multiplication
);

    wire sign_a;
    wire sign_b;
    wire [7:0] exponent_a;
    wire [7:0] exponent_b;
    wire [23:0] mantissa_a;
    wire [23:0] mantissa_b;
    wire sign_result;
    wire [8:0] exponent_result;
    wire [47:0] mantissa_result;
    wire [22:0] mantissa_final;
    wire [7:0] exponent_final;
    wire overflow;

    // Extract sign, exponent, and mantissa
    assign sign_a = a[31];
    assign sign_b = b[31];
    assign exponent_a = a[30:23];
    assign exponent_b = b[30:23];
    assign mantissa_a = {1'b1, a[22:0]}; // Implicit leading 1
    assign mantissa_b = {1'b1, b[22:0]}; // Implicit leading 1

    // Calculate the result sign
    assign sign_result = sign_a ^ sign_b;

    // Add exponents and subtract bias (127)
    assign exponent_result = exponent_a + exponent_b - 8'd127;

    // Multiply mantissas
    assign mantissa_result = mantissa_a * mantissa_b;

    // Normalize the result mantissa and adjust exponent
    assign mantissa_final = mantissa_result[47] ? mantissa_result[46:24] : mantissa_result[45:23];
    assign exponent_final = mantissa_result[47] ? exponent_result + 1 : exponent_result;

    // Check for overflow
    assign overflow = (exponent_final > 8'd254);

    // Handle special cases (NaN, infinity, zero)
    wire a_is_zero = (exponent_a == 8'd0 && a[22:0] == 23'd0);
    wire b_is_zero = (exponent_b == 8'd0 && b[22:0] == 23'd0);
    wire a_is_inf = (exponent_a == 8'd255 && a[22:0] == 23'd0);
    wire b_is_inf = (exponent_b == 8'd255 && b[22:0] == 23'd0);
    wire a_is_nan = (exponent_a == 8'd255 && a[22:0] != 23'd0);
    wire b_is_nan = (exponent_b == 8'd255 && b[22:0] != 23'd0);

    assign result = a_is_nan ? a :
                    b_is_nan ? b :
                    (a_is_inf & b_is_zero) | (b_is_inf & a_is_zero) ? 32'hFFC00000 : // NaN
                    a_is_inf | b_is_inf ? {sign_result, 8'hFF, 23'd0} :
                    a_is_zero | b_is_zero ? {sign_result, 31'd0} :
                    overflow ? {sign_result, 8'hFF, 23'd0} : // Inf
                    {sign_result, exponent_final[7:0], mantissa_final[22:0]};

endmodule

