module tb_fp_add;

    reg [31:0] a, b;
    wire [31:0] result;

    fp_add uut (
        .a(a),
        .b(b),
        .result(result)
    );

    initial begin
        // Test case 1: Adding two normal numbers
        a = 32'h40400000; // 3.0
        b = 32'h40400000; // 3.0
        #10;
        $display("Test 1: a = %h, b = %h, result = %h", a, b, result);

        // Test case 2: Adding a number and zero
        a = 32'h00000000; // 0.0
        b = 32'h40400000; // 3.0
        #10;
        $display("Test 2: a = %h, b = %h, result = %h", a, b, result);

        // Test case 3: Adding a number and infinity
        a = 32'h7F800000; // +Infinity
        b = 32'h40400000; // 3.0
        #10;
        $display("Test 3: a = %h, b = %h, result = %h", a, b, result);

        // Test case 4: Adding two negative numbers
        a = 32'hC0400000; // -3.0
        b = 32'hC0400000; // -3.0
        #10;
        $display("Test 4: a = %h, b = %h, result = %h", a, b, result);

        // Test case 5: Adding a NaN and a number
        a = 32'h7FC00000; // NaN
        b = 32'h40400000; // 3.0
        #10;
        $display("Test 5: a = %h, b = %h, result = %h", a, b, result);

        // Test case 5: Adding a NaN and a number
        a = 32'h40200000; // 2.5
        b = 32'h40500000; // 3.25
        #10;
        $display("Test 5: a = %h, b = %h, result = %h", a, b, result);

        $stop;
    end
endmodule
