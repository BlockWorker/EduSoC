package registers;
  typedef enum logic [1:0] {
    MAIN = 0,
    SET  = 1,
    CLR  = 2,
    INV  = 3
  } reg_access_t;

  function logic [31:0] writeval(input logic [31:0] current, input logic [31:0] write, input reg_access_t reg_type);
    case (reg_type)
      MAIN: writeval = write;
      SET: writeval = current | write;
      CLR: writeval = current & ~(write);
      INV: writeval = current ^ write;
      default: writeval = current;
    endcase
  endfunction

  function logic [31:0] clearonly(input logic [31:0] current, input logic [31:0] value, input reg_access_t reg_type);
    case (reg_type)
      MAIN: clearonly = current & value;
      CLR, INV: clearonly = current & ~value;
      default: clearonly = current;
    endcase
  endfunction
endpackage
