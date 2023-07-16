module AHB_Slave_Slow #(DATA_WIDTH = 32, ADDR_WIDTH = 32, HBURST_WIDTH = 3, HPROT_WIDTH = 4, OFFSET = 0)(
    input h_clk, //GLOBAL
    input h_resetn, //GLOBAL
    input h_sel, //DEC -> SLV
    input [ADDR_WIDTH-1:0] h_addr, //MST -> SLV
    input [HBURST_WIDTH-1:0] h_burst, //MST -> SLV
    input h_mst_lock, //MST -> SLV
    input [2:0] h_size, //MST -> SLV
    input h_nonsec, //MST -> SLV/DEC
    input [1:0] h_trans, //MST -> SLV
    input [DATA_WIDTH-1:0] h_wdata, //MST -> SLV
    input [(DATA_WIDTH/4)-1:0] h_wstrb, //MST - > SLV
    input h_write, //MST -> SLV  
    input h_ready, //MUX -> SLV
    output logic [DATA_WIDTH-1:0] h_rdata, //SLV -> MUX
    output logic h_ready_out, //SLV -> MUX
    output logic h_resp //SLV -> MUX
    );
    
    //Transfer types
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;    
    
    //Burst types
    localparam SINGLE = 3'b000;
    localparam INCR = 3'b001;
    localparam WRAP4 = 3'b010;
    localparam INCR4 = 3'b011;
    localparam WRAP8 = 3'b100;
    localparam INCR8 = 3'b101;
    localparam WRAP16 = 3'b110;
    localparam INCR16 = 3'b111;
    
    //Transfer lengths
    localparam BYTE_XFR = 3'b000;
    localparam HALFWORD_XFR = 3'b001;
    localparam WORD_XFR = 3'b010;
    
    logic [ADDR_WIDTH-1:0] wrap_threshold, wrap_base; //States the max value addr can take, otherwise we should wrap to base value
    logic [ADDR_WIDTH-1:0] next_h_addr, cur_h_addr; //Address sent to SLV
    logic [6:0] wrap_size; //This determines how we wrap
    logic wrap; //States if we are doing a wrap transfer
    logic [3:0] burst_size, burst_cnt; //Keeps track of total burst size and current burst size
    logic [7:0] slv_mem [2047:0]; //Memory
    logic req_wait;
    logic burst_completed;
    
    assign wrap = (h_burst == WRAP4) || (h_burst == WRAP8) || (h_burst == WRAP16);
    assign burst_completed = (burst_size == burst_cnt);  
    
    //This block determines the wrap size
    always_comb begin
        case(h_size) 
            BYTE_XFR : begin
                case(h_burst) 
                    WRAP4,INCR4 : begin
                        wrap_size = 4;
                    end
                    WRAP8, INCR8 : begin
                        wrap_size = 8;
                    end
                    WRAP16, INCR16 : begin
                        wrap_size = 16;
                    end
                    default : begin
                        wrap_size = 0;
                    end
                endcase
            end
           HALFWORD_XFR : begin
                case(h_burst) 
                    WRAP4,INCR4 : begin
                        wrap_size = 8;
                    end
                    WRAP8, INCR8 : begin
                        wrap_size = 16;
                    end
                    WRAP16, INCR16 : begin
                        wrap_size = 32;
                    end
                    default : begin
                        wrap_size = 0;
                    end
                endcase
            end
           WORD_XFR : begin
                case(h_burst) 
                    WRAP4,INCR4 : begin
                        wrap_size = 16;
                    end
                    WRAP8, INCR8 : begin
                        wrap_size = 32;
                    end
                    WRAP16, INCR16 : begin
                        wrap_size = 64;
                    end
                    default : begin
                        wrap_size = 0;
                    end
                endcase
            end
            default : begin
                wrap_size = 0;
            end
        endcase
    end 
     
    //This block determines the current address and wrap thresholds
    always_comb begin
        case(h_trans)
            IDLE : begin
                cur_h_addr = h_addr;
                wrap_threshold = 0;
                wrap_base = 0;
            end
            
            BUSY : begin
                cur_h_addr = next_h_addr;
                wrap_threshold = 0;
                wrap_base = 0;
            end
            
            NONSEQ : begin
                cur_h_addr = h_addr; 
                wrap_threshold = (h_addr + wrap_size) - (h_addr % wrap_size); //Determine wrap location or threshold
                wrap_base = h_addr - (h_addr % wrap_size); //Determine base
            end
            
            SEQ : begin
                if(h_ready_out == 1) begin
                    cur_h_addr = next_h_addr;
                end else begin
                    cur_h_addr = cur_h_addr;
                end
                wrap_threshold = 0;
                wrap_base = 0;
            end
            
            default : begin
                cur_h_addr = 0;
                wrap_threshold = 0;
                wrap_base = 0;  
            end        
        endcase
    end
    
    //This block tracks burst count
    always_ff @(posedge h_clk or negedge h_resetn) begin
        if(!h_resetn) begin
            burst_size <= 0;
            burst_cnt <= 0;
        end    
        else if(h_trans == NONSEQ || burst_cnt == burst_size) begin
            burst_cnt <= 0;
            case(h_burst) 
                INCR4, WRAP4 : begin
                    burst_size = 3;
                end
                INCR8, WRAP8 : begin
                    burst_size = 7;
                end
                INCR16, WRAP16 : begin
                    burst_size = 15;
                end
                default : begin
                    burst_size = 0;
                end
            endcase
        end
        else if(h_trans == SEQ && burst_cnt != burst_size && h_burst != INCR && h_ready == 1) begin
            burst_cnt <= burst_cnt + 1;
        end
    end
    
    //This block controlls the next address 
    always_ff @(posedge h_clk or negedge h_resetn) begin
        if(!h_resetn) begin
            next_h_addr <= '0;
        end    
        else if(burst_cnt == burst_size && h_burst != INCR) begin
            next_h_addr <= h_addr;
        end else if((h_trans == SEQ || h_trans == NONSEQ) && h_ready == 1) begin 
            case(h_size) 
                BYTE_XFR : begin
                    if((cur_h_addr + 1 >= wrap_threshold) && (wrap == 1) ) begin
                        next_h_addr <= wrap_base + ((cur_h_addr + 1) % wrap_size);
                    end else begin
                        next_h_addr <= cur_h_addr + 1;
                    end
                end
                HALFWORD_XFR : begin
                    if((cur_h_addr + 2 >= wrap_threshold) && (wrap == 1)) begin
                        next_h_addr <= wrap_base + ((cur_h_addr + 2) % wrap_size);
                    end else begin
                        next_h_addr <= cur_h_addr + 2;
                    end
                end
                WORD_XFR : begin
                    if((cur_h_addr + 4 >= wrap_threshold) && (wrap == 1)) begin
                        next_h_addr <= wrap_base + ((cur_h_addr + 4) % wrap_size);
                    end else begin
                        next_h_addr <= cur_h_addr + 4;
                    end
                end
                default : begin
                    next_h_addr <= 0;
                end
            endcase   
        end else begin
            next_h_addr <= next_h_addr;
        end
    end
    
    //This block ready and writes the data, as well as updates our address
    always_ff @(posedge h_clk or negedge h_resetn) begin
        if(!h_resetn) begin
            h_ready_out <= 1;
            h_resp <= 0;
            h_rdata <= '0;
            req_wait <= 1;
            for(int i = 0; i < 2048; i++) begin
                slv_mem[i] <= '0;
            end
        end
        else if(h_sel) begin
            case(h_trans) 
                IDLE : begin
                    req_wait <= 0;
                    h_ready_out <= 1;
                    h_resp <= 0;
                    h_rdata <= '0;
                end
                
                BUSY , NONSEQ, SEQ : begin
                    h_ready_out <= 1;   //TODO : Will need to modify
                    h_resp <= 0;
                    if(!req_wait) begin
                        case(h_size)
                            BYTE_XFR : begin
                                if(h_write) begin
                                    slv_mem[cur_h_addr - OFFSET] <= h_wdata[7:0];
                                end else begin
                                    h_rdata <= {24'h0, slv_mem[cur_h_addr]};
                                end
                                h_resp <= 0;
                            end
                            
                            HALFWORD_XFR : begin
                                if(h_write) begin
                                    slv_mem[cur_h_addr - OFFSET] <= h_wdata[7:0];
                                    slv_mem[cur_h_addr - OFFSET + 1] <= h_wdata[15:8];
                                end else begin
                                    h_rdata <= {16'h0, slv_mem[cur_h_addr - OFFSET + 1], slv_mem[cur_h_addr - OFFSET]};
                                end
                                h_resp <= 0;
                            end
                            
                            WORD_XFR : begin
                                if(h_write) begin
                                    slv_mem[cur_h_addr - OFFSET] <= h_wdata[7:0];
                                    slv_mem[cur_h_addr - OFFSET + 1] <= h_wdata[15:8];
                                    slv_mem[cur_h_addr - OFFSET + 2] <= h_wdata[23:16];
                                    slv_mem[cur_h_addr - OFFSET + 3] <= h_wdata[31:24];
                                end else begin
                                    h_rdata <= {slv_mem[cur_h_addr - OFFSET + 3], slv_mem[cur_h_addr - OFFSET + 2], slv_mem[cur_h_addr - OFFSET + 1], slv_mem[cur_h_addr - OFFSET]};
                                end
                                h_resp <= 0;
                            end
                            
                            default : begin
                                h_resp <= 1; 
                                h_rdata <= '0;
                            end
                        endcase
                     end
                     else if(req_wait) begin
                        req_wait <= 0;
                        h_ready_out <= 0;
                        h_resp <= 0;
                        h_rdata <= '0; 
                     end   
                end
            endcase        
        end 
        else begin
            req_wait <= 1;
            h_ready_out <= 1;
            h_resp <= 0;
            h_rdata <= '0;
        end
    end
    
endmodule