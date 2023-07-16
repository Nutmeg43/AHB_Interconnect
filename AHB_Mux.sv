module AHB_Mux #(DATA_WIDTH = 32)(
    input h_clk, //GLOBAL
    input h_resetn, //GLOBAL
    input [DATA_WIDTH-1:0] h_rdata_x [4:0], //SLVx -> MUX
    input [4:0] h_sel_x, //DEC -> MUX
    input [5:0] h_ready_x, //SLVx -> MUX
    input [5:0] h_resp_x, //SLVx -> MST
    output logic [DATA_WIDTH-1:0] h_rdata, //MUX -> MST
    output logic h_ready, //MUX -> MST/SLV
    output logic h_resp //MUX -> MST    
    );
    
    logic [4:0] h_sel_chk; //States which SLV we should check
    
    always_ff @(posedge h_clk) begin
        if(h_ready == 1) begin
            h_sel_chk <= h_sel_x;
        end   
    end
    
    always_comb begin    
        if(!h_resetn) begin
            h_ready = 1;
            h_resp = 0;
            h_rdata = '0;
        end
        else begin
            case(h_sel_chk) 
                
                //Default SLV
                5'b00000 : begin 
                    h_ready = h_ready_x[5];
                    h_resp = h_resp_x[5];
                    h_rdata = '0;
                end
                
                5'b00001 : begin
                    h_ready = h_ready_x[0];
                    h_resp = h_resp_x[0];
                    if(h_ready_x[0]) begin
                        h_rdata = h_rdata_x[0];
                    end
                end
                
                5'b00010 : begin
                    h_ready = h_ready_x[1];
                    h_resp = h_resp_x[1];
                    if(h_ready_x[1]) begin
                        h_rdata = h_rdata_x[1];
                    end
                end
                
                5'b00100 : begin
                    h_ready = h_ready_x[2];
                    h_resp = h_resp_x[2];
                    if(h_ready_x[2]) begin
                        h_rdata = h_rdata_x[2];
                    end
                end
                
                5'b01000 : begin
                    h_ready = h_ready_x[3];
                    h_resp = h_resp_x[3];
                    if(h_ready_x[3]) begin
                        h_rdata = h_rdata_x[3];
                    end
                end
                
                5'b10000 : begin
                    h_ready = h_ready_x[4];
                    h_resp = h_resp_x[4];
                    if(h_ready_x[4]) begin
                        h_rdata = h_rdata_x[4];
                    end
                end
            
                default : begin
                    h_ready = 1;
                    h_resp = 0;
                    h_rdata = '0;
                end
            endcase  
            
        end   
    end
    
endmodule
