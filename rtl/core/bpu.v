`include "defines.v"

module bpu(
   input wire clk,
   input wire rst,
   
   input wire[`InstBus] inst_i,
   input wire[`InstAddrBus] inst_addr_i,
   input wire last_jump_i, 
   input wire[`InstAddrBus] last_addr_i,
   input wire last_need_predict_i,

   output reg bp_result_o,
   output reg[`InstAddrBus] bp_jump_addr_o
);

  wire[6:0] opcode;
  wire[`InstAddrBus] jal_addr;
  wire[`InstAddrBus] b_addr;
  
  assign opcode = inst_i[6:0];
  assign jal_addr =  {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0} + inst_addr_i;
  assign b_addr = {{20{inst_i[31]}}, inst_i[7], inst_i[30:25], inst_i[11:8], 1'b0} + inst_addr_i;

  reg[2:0] state;
  // 00 -- strongly not taken
  // 01 -- weakly not taken
  // 10 -- weakly not taken
  // 11 -- strongly not taken

  always @(posedge clk) begin
    if (rst == `RstEnable) begin
        state <= 2'b00;
    end else 
    if (last_need_predict_i == 1'b1) begin
        case (state)
            2'b00: begin
                if (last_jump_i == 1'b1) begin
                    state <= 2'b01;
                end else begin
                    state <= 2'b00;
                end
            end
            2'b01: begin
                if (last_jump_i == 1'b1) begin
                    state <= 2'b10;
                end else begin
                    state <= 2'b00;
                end
            end
            2'b10: begin
                if (last_jump_i == 1'b1) begin
                    state <= 2'b11;
                end else begin
                    state <= 2'b01;
                end
            end
            2'b11: begin
                if (last_jump_i == 1'b1) begin
                    state <= 2'b11;
                end else begin
                    state <= 2'b10;
                end
            end
            default: begin end 
        endcase
    end



  end
  
  always @ (*) begin
    bp_result_o = `JumpDisable;
    bp_jump_addr_o = `ZeroWord; 
     
    case (opcode)
      `INST_JAL: begin
        bp_jump_addr_o = jal_addr;                              // static predictor
        //bp_result_o = 1'b1;                                     // static predictor
        bp_result_o = (state == 2'b10) || (state == 2'b11);     // 2-bit counter 
      end
      `INST_TYPE_B:begin
        bp_jump_addr_o = b_addr;                                // static predictor
        //bp_result_o = $signed(b_addr) < $signed(inst_addr_i);   // static predictor
        bp_result_o = (state == 2'b10) || (state == 2'b11);     // 2-bit counter 
      end 
      default: begin
      end

    endcase
  end
endmodule
