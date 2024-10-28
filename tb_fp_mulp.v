module tb_fp_mul;

    reg [31:0] a, b;
    wire [31:0] result;

    fp_mul uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        // Test case 1: Multiplying two normal numbers
        a = 32'h40400000; // 3.0
        b = 32'h40800000; // 4.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // Test case 2: Multiplying a number by zero
        a = 32'h00000000; // 0.0
        b = 32'h40800000; // 4.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // Test case 3: Multiplying a number by infinity
        a = 32'h7F800000; // +Infinity
        b = 32'h40400000; // 3.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // Test case 4: Multiplying two negative numbers
        a = 32'hC0400000; // -3.0
        b = 32'hC0800000; // -4.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // Test case 5: Multiplying a NaN by a number
        a = 32'h7FC00000; // NaN
        b = 32'h40400000; // 3.0
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        // Test case 5: Multiplying a NaN by a number
        a = 32'h40200000; // 2.5
        b = 32'h40200000; // 2.5
        #10;
        $display("a = %h, b = %h, result = %h", a, b, result);

        $stop;
    end
endmodule

