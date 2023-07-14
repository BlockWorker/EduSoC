package registers;
  typedef enum logic [1:0] {
    MAIN = 0,
    SET  = 1,
    CLR  = 2,
    INV  = 3
  } reg_access_t;

  function writeval(input logic current, input logic write, input reg_access_t reg_type);
    case (reg_type)
      MAIN: writeval = write;
      SET: writeval = current | write;
      CLR: writeval = current & ~(write);
      INV: writeval = current ^ write;
      default: writeval = current;
    endcase
  endfunction

  function clearonly(input logic current, input logic value, input reg_access_t reg_type);
    if (reg_type != SET) clearonly = current & ~value;
    else clearonly = current;
  endfunction
endpackage
