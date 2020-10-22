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

//begin:  2-bit branch predictor

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
// end: 2-bit branch predictor 

// begin: one-level branch predictor(Decode History Table)
  reg[3:0] dht[31:0];
  integer last_5, upper, lower ;
  always @(posedge clk) begin
    if (rst == `RstEnable) begin
        for (last_5 = 0; last_5 <= 31; last_5 = last_5 + 1)
            dht[last_5] = 2'b00;
    end else begin 
    if (last_need_predict_i == 1'b1) begin
        for (last_5 = 0; last_5 <32; last_5 += 1) begin
            if (last_5 == last_addr_i[4:0]) begin
                case (dht[last_5])
                    2'b00: begin
                        if (last_jump_i == 1'b1) begin
                            dht[last_5] <= 2'b01;
                        end else begin
                            dht[last_5] <= 2'b00;
                        end
                    end
                    2'b01: begin
                        if (last_jump_i == 1'b1) begin
                            dht[last_5] <= 2'b10;
                        end else begin
                            dht[last_5] <= 2'b00;
                        end
                    end
                    2'b10: begin
                        if (last_jump_i == 1'b1) begin
                            dht[last_5] <= 2'b11;
                        end else begin
                            dht[last_5] <= 2'b01;
                        end
                    end
                    2'b11: begin
                        if (last_jump_i == 1'b1) begin
                            dht[last_5] <= 2'b11;
                        end else begin
                            dht[last_5] <= 2'b10;
                        end
                    end
                    default: begin end 
                endcase
            end
        end
        end
    end
  end

// end: one-level branch predictor
// 
// begin: two-level adaptive branch predictor

    reg[4:0] c_reg[31:0];
    reg[1:0] gpt[31:0];
    integer i_5, j_5;
    reg[4:0] tmp_reg;

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            for (i_5 = 0; i_5 < 32; i_5 = i_5 + 1) begin
                c_reg[i_5] <= 5'b0;
                gpt[i_5] <= 2'b0;
            end
        end else begin
            if (last_need_predict_i == 1'b1) begin
                for (i_5 = 0; i_5 < 32; i_5 = i_5 + 1) begin
                    if (i_5 == last_addr_i[4:0]) begin
                        tmp_reg = {c_reg[i_5][3:0], last_jump_i};
                        c_reg[i_5] = tmp_reg;
                        
                        for (j_5 = 0; j_5 < 32; j_5 += 1) begin
                            if (j_5 == tmp_reg) begin
                                case (gpt[j_5])
                                    2'b00: begin
                                        if (last_jump_i == 1'b1) begin
                                            gpt[j_5] <= 2'b01;
                                        end else begin
                                            gpt[j_5] <= 2'b00;
                                        end
                                    end
                                    2'b01: begin
                                        if (last_jump_i == 1'b1) begin
                                            gpt[j_5] <= 2'b10;
                                        end else begin
                                            gpt[j_5] <= 2'b00;
                                        end
                                    end
                                    2'b10: begin
                                        if (last_jump_i == 1'b1) begin
                                            gpt[j_5] <= 2'b11;
                                        end else begin
                                            gpt[j_5] <= 2'b01;
                                        end
                                    end
                                    2'b11: begin
                                        if (last_jump_i == 1'b1) begin
                                            gpt[j_5] <= 2'b11;
                                        end else begin
                                            gpt[j_5] <= 2'b10;
                                        end
                                    end
                                    default: begin end 
                                endcase
                            end
                        end
                    end

                end
            end
        end

    end
// end: two-level adaptive branch predictor


  
  always @ (*) begin
    bp_result_o = `JumpDisable;
    bp_jump_addr_o = `ZeroWord; 
     
    case (opcode)
      `INST_JAL: begin
        bp_jump_addr_o = jal_addr;                              // static predictor
//      bp_result_o = 1'b1;                                     // static predictor
        bp_result_o = (state == 2'b10) || (state == 2'b11);     // 2-bit branch prediction 
/*
        for (last_5=0; last_5 < 32; last_5 = last_5 + 1) begin  // one-level branch prediction
            if (last_5 == last_addr_i[4:0]) begin
                bp_result_o = (dht[last_5] == 2'b10) || (dht[last_5] == 2'b11);
            end
        end
*/
/*
        for (i_5 = 0; i_5 < 32; i_5 = i_5 + 1) begin
            if (i_5 == last_addr_i[4:0]) begin
                tmp_reg = c_reg[i_5];
                for (j_5 = 0; j_5 < 32; j_5 = j_5 + 1) begin
                    if (j_5 == tmp_reg) begin
                        bp_result_o = (gpt[j_5] == 2'b10) || (gpt[j_5] == 2'b11);
                    end
                end
            end
        end
*/
      end
      `INST_TYPE_B:begin
        bp_jump_addr_o = b_addr;                                // static predictor
//      bp_result_o = $signed(b_addr) < $signed(inst_addr_i);   // static predictor
        bp_result_o = (state == 2'b10) || (state == 2'b11);     // 2-bit branch prediction 
/*
        for (last_5=0; last_5 < 32; last_5 = last_5 + 1) begin  // one-level branch prediction
            if (last_5 == last_addr_i[4:0]) begin
                bp_result_o = (dht[last_5] == 2'b10) || (dht[last_5] == 2'b11);
            end
        end
*/
/*
        for (i_5 = 0; i_5 < 32; i_5 = i_5 + 1) begin
            if (i_5 == last_addr_i[4:0]) begin
                tmp_reg = c_reg[i_5];
                for (j_5 = 0; j_5 < 32; j_5 = j_5 + 1) begin
                    if (j_5 == tmp_reg) begin
                        bp_result_o = (gpt[j_5] == 2'b10) || (gpt[j_5] == 2'b11);
                    end
                end
            end
        end
*/
      end 
      default: begin
      end

    endcase
  end
endmodule
