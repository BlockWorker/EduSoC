module pc_tb();

    reg [31:0] D;
    reg MODE;
    reg ENABLE;
    reg RES;
    reg CLK;
    wire [31:0] PC_OUT;
    reg [31:0] random_value;

    pc dut(.D(D), .MODE(MODE), .ENABLE(ENABLE), .RES(RES), .CLK(CLK), .PC_OUT(PC_OUT));

    initial begin
        CLK = 0;
        RES = 0;
    end

    always #5 CLK = ~CLK;

    always begin
        //test reset
        @(negedge CLK);
        RES = 1;
        @(negedge CLK);
        RES = 0;
        if (PC_OUT != 32'h1A000000) begin
            $display("Reset failed");
            $finish;
        end
        //test increment
        D = $urandom; //put random data into D, shouldn't be used
        MODE = 0; //set increment mode
        ENABLE = 0; //try without enable first
        @(negedge CLK);
        if (PC_OUT != 32'h1A000000) begin //nothing should have changed
            $display("Test failed: Mode 0, Enable 0 caused counter change");
            $finish;
        end
        ENABLE = 1; //set enable now
        @(negedge CLK);
        if (PC_OUT != 32'h1A000004) begin //counter should be incremented by 4
            $display("Increment failed");
            $finish;
        end
        //test jump
        random_value = $urandom; //set up random jump data and jump mode, without enable for now
        D = random_value;
        MODE = 1;
        ENABLE = 0;
        @(negedge CLK);
        if (PC_OUT != 32'h1A000004) begin //nothing should have changed
            $display("Test failed: Mode 1, Enable 0 caused counter change");
            $finish;
        end
        ENABLE = 1; //set enable now
        @(negedge CLK);
        if (PC_OUT != random_value) begin //counter should be loaded with jump target
            $display("Jump failed");
            $finish;
        end
        $display("All tests finished successfully");
        $finish;
    end    

endmodule
