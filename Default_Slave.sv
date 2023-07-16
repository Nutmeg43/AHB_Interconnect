module Default_Slave (
    input h_clk, //GLOBAL
    input h_resetn, //GLOBAL
    input [4:0] h_sel, //DEC -> SLV
    input [1:0] h_trans, //MST -> SLV
    input h_ready, //MUX -> SLV
    output logic h_ready_out, //SLV -> MUX
    output logic h_resp //SLV -> MUX
    );
    

    //Transfer types
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;    
 
    //This block ready and writes the data, as well as updates our address
    always_ff @(posedge h_clk or negedge h_resetn) begin
        if(!h_resetn) begin
            h_ready_out <= 1;
            h_resp <= 0;
        end
        else if(h_sel == 5'b00000 && (h_trans == NONSEQ || h_trans == SEQ) && !h_resp) begin
            h_ready_out <= 0;
            h_resp <= 1;
        end
        else if(h_sel == 5'b00000 && (h_trans == NONSEQ || h_trans == SEQ) && h_resp) begin
            h_ready_out <= 1;
            h_resp <= 1;
        end 
        else begin
            h_ready_out <= 1;
            h_resp <= 0;
        end
    end
    
endmodule