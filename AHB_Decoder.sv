module AHB_Decoder #(ADDR_WIDTH = 32)(
    input [ADDR_WIDTH-1:0] h_addr, //MST -> DEC
    output logic [4:0] h_sel_x //DEC -> SLVx
    );
    
    always_comb begin
        if(h_addr >= 0 && h_addr < 'h800) begin
            h_sel_x = 5'b00001;
        end    
        else if(h_addr >= 'h800 && h_addr < 'h1000) begin
            h_sel_x = 5'b00010;
        end 
        else if(h_addr >= 'h1000 && h_addr < 'h1800) begin
            h_sel_x = 5'b00100;
        end 
        else if(h_addr >= 'h2000 && h_addr < 'h2800) begin
            h_sel_x = 5'b01000;
        end 
        else if(h_addr >= 'h3000 && h_addr < 'h3800) begin
            h_sel_x = 5'b10000;
        end 
        else begin //Default SLV
            h_sel_x = 5'b00000;
        end
    end
    
endmodule
