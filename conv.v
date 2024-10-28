module convolution(
    input clk,
    input rst,
    input [31:0] data_in,
    input [7:0] input_size,
    input [7:0] filter_size,
    output reg [31:0] data_out,
    output reg done
);

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

    reg [31:0] input_matrix [0:255][0:255];  // Max size 256x256
    reg [31:0] filter_matrix [0:15][0:15];   // Max size 16x16
    reg [31:0] output_matrix [0:255][0:255]; // Output matrix
    
    integer i, j, m, n;
    reg [7:0] row_count;
    reg [7:0] col_count;
    reg [7:0] filter_row;
    reg [7:0] filter_col;
    reg [31:0] sum;
    reg [31:0] buff;
    reg [7:0] input_index;
    reg [7:0] filter_index;
    reg [3:0] state;

    parameter IDLE = 0,
              READ_INPUT = 1,
              READ_FILTER = 2,
              CONVOLVE = 3,
              WRITE_OUTPUT = 4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            row_count <= 0;
            col_count <= 0;
            filter_row <= 0;
            filter_col <= 0;
            input_index <= 0;
            filter_index <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: begin
                    row_count <= 0;
                    col_count <= 0;
                    filter_row <= 0;
                    filter_col <= 0;
                    input_index <= 0;
                    filter_index <= 0;
                    done <= 0;
                    state <= READ_INPUT;
                end

                READ_INPUT: begin
                    if (input_index < input_size * input_size) begin
                        input_matrix[input_index / input_size][input_index % input_size] = data_in;
                        input_index <= input_index + 1;
                    end else begin
                        if (filter_index < filter_size * filter_size) begin
                            filter_matrix[filter_index / filter_size][filter_index % filter_size] = data_in;
                            filter_index <= filter_index + 1;
                        end else begin
                            state <= CONVOLVE;
                            filter_index <= 0;
                            row_count <= 0;
                            col_count <= 0;
                        end
                    end
                end

                CONVOLVE: begin
                    if (row_count <= input_size - filter_size) begin
                        if (col_count <= input_size - filter_size) begin
                            sum = 0;
                            for (m = 0; m < filter_size; m = m + 1) begin
                                for (n = 0; n < filter_size; n = n + 1) begin
                                    buff = fp_add_func(sum , fp_mul_func(input_matrix[row_count + m][col_count + n] , filter_matrix[m][n]));
                                    sum = buff;
                                    // sum = sum + input_matrix[row_count + m][col_count + n] * filter_matrix[m][n];
                                end
                            end
                            output_matrix[row_count][col_count] = sum;
                            col_count <= col_count + 1;
                        end else begin
                            col_count <= 0;
                            row_count <= row_count + 1;
                        end
                    end else begin
                        state <= IDLE;
                        row_count <= 0;
                        col_count <= 0;
                        done <= 1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
