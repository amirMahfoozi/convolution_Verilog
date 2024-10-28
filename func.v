module test();
function [31:0] fp_add_func;
    input [31:0] a;    // First 32-bit floating-point number
    input [31:0] b;    // Second 32-bit floating-point number

    // Local variable declarations
    reg sign_a, sign_b;
    reg [7:0] exponent_a, exponent_b;
    reg [23:0] mantissa_a, mantissa_b;
    reg [23:0] aligned_mantissa_a, aligned_mantissa_b;
    reg [7:0] exponent_diff;
    reg [7:0] exponent_result;
    reg sign_result;
    reg [24:0] mantissa_sum;
    reg [23:0] mantissa_final;
    reg [7:0] exponent_adjusted;
    
    // Flags for special cases
    reg a_is_zero, b_is_zero;
    reg a_is_inf, b_is_inf;
    reg a_is_nan, b_is_nan;

    begin
        // Extract sign, exponent, and mantissa
        sign_a = a[31];
        sign_b = b[31];
        exponent_a = a[30:23];
        exponent_b = b[30:23];
        mantissa_a = (exponent_a == 0) ? {1'b0, a[22:0]} : {1'b1, a[22:0]}; // Handle denormals
        mantissa_b = (exponent_b == 0) ? {1'b0, b[22:0]} : {1'b1, b[22:0]}; // Handle denormals

        // Set flags for special cases
        a_is_zero = (exponent_a == 8'd0 && a[22:0] == 23'd0);
        b_is_zero = (exponent_b == 8'd0 && b[22:0] == 23'd0);
        a_is_inf = (exponent_a == 8'd255 && a[22:0] == 23'd0);
        b_is_inf = (exponent_b == 8'd255 && b[22:0] == 23'd0);
        a_is_nan = (exponent_a == 8'd255 && a[22:0] != 23'd0);
        b_is_nan = (exponent_b == 8'd255 && b[22:0] != 23'd0);

        // Align exponents by shifting the mantissa of the smaller exponent
        exponent_diff = (exponent_a > exponent_b) ? (exponent_a - exponent_b) : (exponent_b - exponent_a);
        aligned_mantissa_a = (exponent_a > exponent_b) ? mantissa_a : (mantissa_a >> exponent_diff);
        aligned_mantissa_b = (exponent_b > exponent_a) ? mantissa_b : (mantissa_b >> exponent_diff);
        exponent_result = (exponent_a > exponent_b) ? exponent_a : exponent_b;

        // Add or subtract mantissas based on sign
        mantissa_sum = (sign_a == sign_b) ? ({1'b0, aligned_mantissa_a} + {1'b0, aligned_mantissa_b}) :
                                             (aligned_mantissa_a >= aligned_mantissa_b) ? ({1'b0, aligned_mantissa_a} - {1'b0, aligned_mantissa_b}) :
                                                                                             ({1'b0, aligned_mantissa_b} - {1'b0, aligned_mantissa_a});
        sign_result = (aligned_mantissa_a >= aligned_mantissa_b) ? sign_a : sign_b;

        // Normalize the result mantissa
        mantissa_final = mantissa_sum[24] ? mantissa_sum[24:1] : mantissa_sum[23:0];
        exponent_adjusted = mantissa_sum[24] ? exponent_result + 1 : exponent_result;

        // Return the result handling special cases
        fp_add_func = a_is_nan ? a :
                       b_is_nan ? b :
                       (a_is_inf & b_is_inf & (sign_a != sign_b)) ? 32'hFFC00000 : // NaN
                       a_is_inf ? a :
                       b_is_inf ? b :
                       a_is_zero ? b :
                       b_is_zero ? a :
                       {sign_result, exponent_adjusted[7:0], mantissa_final[22:0]};
    end
endfunction

function [31:0] fp_mul_func;
    input [31:0] a;    // First 32-bit floating-point number
    input [31:0] b;    // Second 32-bit floating-point number

    // Local variable declarations
    reg sign_a;
    reg sign_b;
    reg [7:0] exponent_a;
    reg [7:0] exponent_b;
    reg [23:0] mantissa_a;
    reg [23:0] mantissa_b;
    reg sign_result;
    reg [8:0] exponent_result;
    reg [47:0] mantissa_result;
    reg [22:0] mantissa_final;
    reg [7:0] exponent_final;
    reg overflow;

    // Flags for special cases
    reg a_is_zero, b_is_zero;
    reg a_is_inf, b_is_inf;
    reg a_is_nan, b_is_nan;

    begin
        // Extract sign, exponent, and mantissa
        sign_a = a[31];
        sign_b = b[31];
        exponent_a = a[30:23];
        exponent_b = b[30:23];
        mantissa_a = {1'b1, a[22:0]}; // Implicit leading 1
        mantissa_b = {1'b1, b[22:0]}; // Implicit leading 1

        // Set flags for special cases
        a_is_zero = (exponent_a == 8'd0 && a[22:0] == 23'd0);
        b_is_zero = (exponent_b == 8'd0 && b[22:0] == 23'd0);
        a_is_inf = (exponent_a == 8'd255 && a[22:0] == 23'd0);
        b_is_inf = (exponent_b == 8'd255 && b[22:0] == 23'd0);
        a_is_nan = (exponent_a == 8'd255 && a[22:0] != 23'd0);
        b_is_nan = (exponent_b == 8'd255 && b[22:0] != 23'd0);

        // Calculate the result sign
        sign_result = sign_a ^ sign_b;

        // Add exponents and subtract bias (127)
        exponent_result = exponent_a + exponent_b - 8'd127;

        // Multiply mantissas
        mantissa_result = mantissa_a * mantissa_b;

        // Normalize the result mantissa and adjust exponent
        mantissa_final = mantissa_result[47] ? mantissa_result[46:24] : mantissa_result[45:23];
        exponent_final = mantissa_result[47] ? exponent_result + 1 : exponent_result;

        // Check for overflow
        overflow = (exponent_final > 8'd254);

        // Return the result handling special cases
        fp_mul_func = a_is_nan ? a :
                       b_is_nan ? b :
                       (a_is_inf & b_is_zero) | (b_is_inf & a_is_zero) ? 32'hFFC00000 : // NaN
                       a_is_inf | b_is_inf ? {sign_result, 8'hFF, 23'd0} :
                       a_is_zero | b_is_zero ? {sign_result, 31'd0} :
                       overflow ? {sign_result, 8'hFF, 23'd0} : // Inf
                       {sign_result, exponent_final[7:0], mantissa_final[22:0]};
    end
endfunction


reg [31:0] a [2:0][2:0];
reg [31:0] b [2:0][2:0];
reg [31:0] result;
integer i,j;
initial begin
        a[0][0] = 32'h3f800000; // Example value (1.0)
        b[0][0] = 32'h40000000; // Example value (2.0)
        a[1][0] = 32'h30800000; // Example value (1.0)
        b[1][0] = 32'h41000000; // Example value (2.0)
        a[2][0] = 32'h3f800000; // Example value (1.0)
        b[2][0] = 32'h42000000; // Example value (2.0)

        a[0][1] = 32'h3f800000; // Example value (1.0)
        b[0][1] = 32'h40000000; // Example value (2.0)
        a[1][1] = 32'h30800000; // Example value (1.0)
        b[1][1] = 32'h41000000; // Example value (2.0)
        a[2][1] = 32'h3f800000; // Example value (1.0)
        b[2][1] = 32'h42000000; // Example value (2.0)

        a[0][2] = 32'h3f800000; // Example value (1.0)
        b[0][2] = 32'h40000000; // Example value (2.0)
        a[1][2] = 32'h30800000; // Example value (1.0)
        b[1][2] = 32'h41000000; // Example value (2.0)
        a[2][2] = 32'h3f800000; // Example value (1.0)
        b[2][2] = 32'h42000000; // Example value (2.0)
        for(i = 0;i<3;i = i + 1) begin
          for(j = 0;j<3;j = j + 1)begin
            result = fp_add_func(a[i][j],fp_mul_func(a[i][j], b[i][j])); // Call the function
            $display("Result: %h %h %h",a[i][j],b[i][j], result); // Display the result
          end
        end
        
end
endmodule