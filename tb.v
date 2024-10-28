module tb_convolution();

    reg clk;
    reg rst;
    reg [31:0] data_in;
    reg [7:0] input_size;
    reg [7:0] filter_size;
    wire [31:0] data_out;
    wire done;

    // Instantiate the convolution module
    convolution uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .input_size(input_size),
        .filter_size(filter_size),
        .data_out(data_out),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
    end
    always begin
        #5 clk = ~clk;
    end

    // Testbench variables
    integer i, j;
    reg [31:0] input_matrix [3:0][3:0];
    reg [31:0] filter_matrix [1:0][1:0];
    reg [31:0] output_matrix [2:0][2:0];

    initial begin
        // Initialize testbench
        rst = 1;
        data_in = 0;
        input_size = 4; // 4x4 input matrix
        filter_size = 2; // 2x2 filter matrix

        // Initialize input matrix with IEEE 754 representations
        input_matrix[0][0] = 32'h3f800000; // 1.0
        input_matrix[0][1] = 32'h40000000; // 2.0
        input_matrix[0][2] = 32'h40400000; // 3.0
        input_matrix[0][3] = 32'h40800000; // 4.0
        input_matrix[1][0] = 32'h41400000; // 5.0
        input_matrix[1][1] = 32'h41800000; // 6.0
        input_matrix[1][2] = 32'h41c00000; // 7.0
        input_matrix[1][3] = 32'h42000000; // 8.0
        input_matrix[2][0] = 32'h41e00000; // 9.0
        input_matrix[2][1] = 32'h41f00000; // 10.0
        input_matrix[2][2] = 32'h41b00000; // 11.0
        input_matrix[2][3] = 32'h41c80000; // 12.0
        input_matrix[3][0] = 32'h41d00000; // 13.0
        input_matrix[3][1] = 32'h41d80000; // 14.0
        input_matrix[3][2] = 32'h41e00000; // 15.0
        input_matrix[3][3] = 32'h41f80000; // 16.0

        // Initialize filter matrix with IEEE 754 representations
        filter_matrix[0][0] = 32'h3f800000; // 1.0
        filter_matrix[0][1] = 32'h00000000; // 0.0
        filter_matrix[1][0] = 32'h00000000; // 0.0
        filter_matrix[1][1] = 32'h3f800000; // 1.0

        // Deassert reset
        #10 rst = 0;

        // Load input matrix into the module
        for (i = 0; i < input_size; i = i + 1) begin
            for (j = 0; j < input_size; j = j + 1) begin
                @(posedge clk);
                data_in = input_matrix[i][j];
            end
        end
        
        #10
        // Load filter matrix into the module
        for (i = 0; i < filter_size; i = i + 1) begin
            for (j = 0; j < filter_size; j = j + 1) begin
                @(posedge clk);
                data_in = filter_matrix[i][j];
            end
        end

        // Wait for computation to finish
        wait(done);

        // Print the output matrix
        $display("Output matrix:");
        for (i = 0; i < input_size - filter_size + 1; i = i + 1) begin
            for (j = 0; j < input_size - filter_size + 1; j = j + 1) begin
                $write("%h ", uut.output_matrix[i][j]); // Print in hexadecimal format
            end
            $display("");
        end

        $stop;
    end
endmodule
