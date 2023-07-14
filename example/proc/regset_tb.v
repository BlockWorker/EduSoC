module regset_tb ();

  reg [31:0] D;
  reg [4:0] A_D;
  reg [4:0] A_Q0;
  reg [4:0] A_Q1;
  reg write_enable;
  reg RES;
  reg CLK;
  wire [31:0] Q0;
  wire [31:0] Q1;
  reg [31:0] random_value;
  integer i;

  regset dut (
      .D(D),
      .A_D(A_D),
      .A_Q0(A_Q0),
      .A_Q1(A_Q1),
      .write_enable(write_enable),
      .RES(RES),
      .CLK(CLK),
      .Q0(Q0),
      .Q1(Q1)
  );

  initial begin
    RES = 0;
    CLK = 0;
    write_enable = 0;
  end

  always #5 CLK = ~CLK;

  always begin
    //test reset
    @(negedge CLK);
    RES = 1;
    @(negedge CLK);
    RES = 0;
    for (i = 0; i < 32; i = i + 1) begin
      A_Q0 = i;
      A_Q1 = i;
      #1;
      if (Q0 != 32'd0 || Q1 != 32'd0) begin
        $display("Reset failed on register %d", i);
        $finish;
      end
    end
    //test zero register
    random_value = $urandom;  //setup random write data and attempt writing to zero register
    write_enable = 1;
    D = random_value;
    A_D = 5'd0;
    @(negedge CLK);
    write_enable = 0;  //reset write enable
    A_Q0 = 5'd0;
    A_Q1 = 5'd0;
    #1;
    if (Q0 != 32'd0 || Q1 != 32'd0) begin  //check that zero register still returns zero
      $display("Zero register test failed");
      $finish;
    end
    //test other registers
    for (i = 1; i < 32; i = i + 1) begin
      random_value = $urandom;  //setup random write data, write_enable = 0
      write_enable = 0;
      D = random_value;
      A_D = i;
      @(negedge CLK);
      A_Q0 = i;
      A_Q1 = i;
      #1;
      if (Q0 != 32'd0 || Q1 != 32'd0) begin  //check that nothing was written
        $display("Test failed: Register %d written despite write_enable=0", i);
        $finish;
      end
      write_enable = 1;  //set write enable
      @(negedge CLK);
      write_enable = 0;  //reset write enable and data inputs
      D = 32'd0;
      A_D = 5'd0;
      A_Q0 = i;
      A_Q1 = 5'd0;
      #1;
      if (Q0 != random_value || Q1 != 32'd0) begin //check that register was written and outputs on Q0
        $display("Register %d test failed on Q0", i);
        $finish;
      end
      A_Q0 = 5'd0;
      A_Q1 = i;
      #1;
      if (Q0 != 32'd0 || Q1 != random_value) begin  //check that output also works on Q1
        $display("Register %d test failed on Q1", i);
        $finish;
      end
    end
    $display("All tests finished successfully");
    $finish;
  end

endmodule
