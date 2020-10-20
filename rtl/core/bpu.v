`include "defines.v"

module bpu(
   input wire clk,
   input wire rst,
   
   input wire[`InstBus] inst_i,
   input wire[`InstAddrBus] inst_addr_i,
   input wire jump_act_i, 

   output reg bp_result_o,
   output reg[`InstAddrBus] bp_jump_addr_o
);

  wire[6:0] opcode;
  wire[`InstAddrBus] jal_addr;
  wire[`InstAddrBus] b_addr;
  
  assign opcode = inst_i[6:0];
  assign jal_addr =  {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + inst_addr_i;
  assign b_addr = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + inst_addr_i;




// static predictor
  always @ (*) begin
    bp_result_o = `JumpDisable;
    bp_jump_addr_o = `ZeroWord; 
     
    case (opcode)
      `INST_JAL: begin
        bp_jump_addr_o = jal_addr;
        bp_result_o = 1'b1; 
      end
      `INST_TYPE_B:begin
        bp_jump_addr_o = b_addr;
        bp_result_o = $signed(b_addr) < $signed(inst_addr_i);
      end 
      default: begin
      end

    endcase
  end
endmodule
