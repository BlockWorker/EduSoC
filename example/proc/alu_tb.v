module alu_tb();
  reg [5:0] S;
  reg [31:0] A;
  reg [31:0] B;
  wire [31:0] Q;
  wire CMP;
  reg [31:0] soll;
  // ALU als Design-Under-Test (DUT) instanziieren
  alu dut(.A(A),.B(B),.S(S),.Q(Q),.CMP(CMP));

  // Folgendes wird ein Mal ausgeführt
  initial begin
    //ADD1
    A = 32'b011; B = 32'b011; S= 6'b000000; soll = 32'b0110; #10
    if( Q != soll)
    begin
      $display("ADD-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    //ADD2
    A = 32'b100; B = 32'b1; S= 6'b000001; soll = 32'b101; #10
    if( Q != soll)
    begin
      $display("ADD-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SUB1
    A = 32'b0110; B = 32'b0100; S= 6'b100001; soll = 32'b0010; #10
    if( Q != soll)
    begin
      $display("SUB-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    //SUB2
    A = 32'b100; B = 32'b101; S= 6'b100001; soll = 32'hffffffff; #10
    if( Q != soll)
    begin
      $display("SUB-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end


    //AND1
    A = 32'b000; B = 32'b101; S= 6'b011100; soll = 32'b000; #10
    if( Q != soll)
    begin
      $display("AND-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    //AND2
    A = 32'b110; B = 32'b101; S= 6'b011101; soll = 32'b100; #10
    if( Q != soll)
    begin
      $display("AND-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //OR1
    A = 32'b000; B = 32'b101; S= 6'b011000; soll = 32'b101; #10
    if( Q != soll)
    begin
      $display("OR-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    //OR2
    A = 32'b110; B = 32'b101; S= 6'b011001; soll = 32'b111; #10
    if( Q != soll)
    begin
      $display("OR-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //XOR1
    A = 32'b000; B = 32'b101; S= 6'b010000; soll = 32'b101; #10
    if( Q != soll)
    begin
      $display("XOR-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //XOR2
    A = 32'b110; B = 32'b101; S= 6'b010001; soll = 32'b011; #10
    if( Q != soll)
    begin
      $display("XOR-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SLL1
    A=32'b001; B=32'b001; S=6'b000100; soll=32'b0010; #10;
    if( Q != soll)
    begin
      $display("SLL\u2423Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SLL2
    A=32'b110; B=32'b010; S=6'b000101; soll=32'b11000; #10;
    if( Q != soll)
    begin
      $display("SLL\u2423Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SRA1
    A=32'hfffffff8; B=32'b010; S=6'b110100; soll=32'hfffffffe; #10;
    if( Q != soll)
    begin
      $display("SRA\u2423Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SRA2
    A=32'b010; B=32'b01; S=6'b110101; soll=32'b01; #10;
    if( Q != soll)
    begin
      $display("SRA\u2423Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    // SRL1
    A=32'b1011; B=32'b01; S=6'b010100; soll=32'b101; #10;
    if( Q != soll)
    begin
      $display("SRL\u2423Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    // SRL2
    A=32'b111; B=32'b010; S=6'b010101; soll=32'b1; #10;
    if( Q != soll)
    begin
      $display("SRL\u2423Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end


    //SLT1
    A=32'b0110; B=32'b010; S=6'b001000; soll=32'b0; #10;
    if( Q != soll)
    begin
      $display("Testmuster\u2423SLT1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SLT2
    A=32'hfffffffe; B=32'b10; S=6'b001001; soll=32'b1; #10;
    if( Q != soll)
    begin
      $display("Testmuster\u2423SLT2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SLTU1
    A=32'b1110; B=32'b1111; S=6'b001100; soll=32'b1; #10;
    if( Q != soll)
    begin
      $display("Testmuster\u2423SLTU1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //SLTU2
    A=32'hfffffffe; B=3'b010; S=6'b001101; soll=32'b0; #10;
    if( Q != soll)
    begin
      $display("Testmuster\u2423SLTU2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    
    //BEQ1
    A = 32'b0; B = 32'b0; S= 6'b000011; soll = 1'b1; #10
    if( CMP != soll)
    begin
      $display("BEQ-Test\u24231\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BEQ2
    A = 32'b0; B = 32'b11; S= 6'b100011; soll = 1'b0; #10
    if( CMP != soll)
    begin
      $display("BEQ-Test\u24232\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BNE1
    A=32'b111; B=32'b111; S=6'b000111; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BNE1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BNE2
    A=32'b101; B=32'b111; S=6'b100111; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BNE2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BLT1
    A=32'b0110; B=32'b010; S=6'b010011; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BLT1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BLT2
    A=32'hfffffffe; B=32'b010; S=6'b110011; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BLT2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGE1
    A=32'b010; B=32'b0110; S=6'b010111; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGE1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGE2
    A=32'b010; B=32'hfffffffe; S=6'b110111; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGE2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGE3
    A=32'b010; B=32'b010; S=6'b110111; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGE3\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
      end

    //BLTU1
    A=32'b0110; B=32'b010; S=6'b011011; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BLTU1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BLTU2
    A=32'hfffffffe; B=32'b010; S=6'b111011; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BLTU2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BLTU3
    A=32'b10; B=32'b110; S=6'b111011; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BLTU3\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGEU1
    A=32'b10; B=32'b110; S=6'b011111; soll=1'b0; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGEU1\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGEU2
    A=32'hfffffffe; B=32'b10; S=6'b111111; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGEU2\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end

    //BGEU3
    A=32'b101; B=32'b101; S=6'b111111; soll=1'b1; #10;
    if( CMP != soll)
    begin
      $display("Testmuster\u2423BGEU3\u2423Fehlgeschlagen:\u2423ist=%h\u2423soll=%h",Q,soll);
      $finish;
    end
    
    $display("Test erfolgreich beendet");
    $finish;
  end
endmodule
