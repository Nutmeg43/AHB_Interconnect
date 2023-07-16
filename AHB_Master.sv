module AHB_Master #(ADDR_WIDTH = 32, HBURST_WIDTH = 3, HPROT_WIDTH = 4, DATA_WIDTH = 32)(
    input h_clk, //GLOBAL
    input h_resetn, //GLOBAL
    input [ADDR_WIDTH-1:0] h_addr, //MST -> SLV
    input logic [DATA_WIDTH-1:0] h_wdata, //MST -> SLV
    input logic [HBURST_WIDTH-1:0] h_burst, //MST -> SLV
    input logic h_mst_lock, //MST -> SLV
    input logic [2:0] h_size, //MST -> SLV
    input logic h_nonsec, //MST -> SLV/DEC
    input logic [(DATA_WIDTH/4)-1:0] h_wstrb, //MST - > SLV
    input logic h_write, //MST -> SLV
    input logic [1:0] h_trans, //MST -> SLV
    
    output logic [DATA_WIDTH-1:0] h_wdata_out, //MST -> SLV
    output logic [HBURST_WIDTH-1:0] h_burst_out, //MST -> SLV
    output logic h_mst_lock_out, //MST -> SLV
    output logic [2:0] h_size_out, //MST -> SLV
    output logic h_nonsec_out, //MST -> SLV/DEC
    output logic [(DATA_WIDTH/4)-1:0] h_wstrb_out, //MST - > SLV
    output logic h_write_out, //MST -> SLV
    output logic [1:0] h_trans_out, //MST -> SLV  
    output logic [DATA_WIDTH-1:0] h_rdata_mst_out, //MST -> OUT 
    output logic h_ready_out, //MUX -> MST
    output logic h_resp //MUX -> MST
    
    );
      
    //Transfer types
    localparam IDLE = 2'b00;
    localparam BUSY = 2'b01;
    localparam NONSEQ = 2'b10;
    localparam SEQ = 2'b11;    
    
    //Burst types
    localparam SINGLE = 3   'b000;
    localparam INCR = 3'b001;
    localparam WRAP4 = 3'b010;
    localparam INCR4 = 3'b011;
    localparam WRAP8 = 3'b100;
    localparam INCR8 = 3'b101;
    localparam WRAP16 = 3'b110;
    localparam INCR16 = 3'b111;
    localparam BYTE_XFR = 3'b000;
    localparam HALFWORD_XFR = 3'b001;
    localparam WORD_XFR = 3'b010;
   
    //Wire con
    logic [DATA_WIDTH-1:0] h_rdata_x [4:0]; //Wires for each of the SLV rdata
    logic [5:0] h_ready_out_x; //Wires for ready signals
    logic [4:0] h_sel_x; //Wires for select signals
    logic [5:0] h_resp_x; //Wires for resp signals
    logic [DATA_WIDTH-1:0] mux_h_rdata; //Wire for MUX rdata out
    
    logic h_ready_out_mux; //Output ready signal from mux
    assign h_ready_out = h_ready_out_mux;
 
    //Manage signals to SLV, and output signals   
    always_comb begin
        if(!h_resetn) begin
            h_wdata_out = '0;
            h_burst_out = 0;
            h_mst_lock_out = 0;
            h_size_out = '0;
            h_nonsec_out = 0;
            h_wstrb_out = '0;
            h_write_out = 0;
            h_rdata_mst_out = '0;
            h_trans_out = '0;
            h_resp = 0;
        end
        else begin
            h_rdata_mst_out = mux_h_rdata;
        end   
    end
 
    AHB_Slave_Slow #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .HBURST_WIDTH(HBURST_WIDTH),
        .OFFSET(0),
        .HPROT_WIDTH(HPROT_WIDTH)
    ) slv_0(
        .h_clk(h_clk),
        .h_resetn(h_resetn),
        .h_sel(h_sel_x[0]),
        .h_addr(h_addr),
        .h_burst(h_burst),
        .h_mst_lock(h_mst_lock),
        .h_size(h_size),
        .h_nonsec(h_nonsec),
        .h_trans(h_trans),
        .h_wdata(h_wdata),
        .h_wstrb(h_wstrb),
        .h_write(h_write),
        .h_rdata(h_rdata_x[0]),
        .h_ready(h_ready_out_mux),
        .h_ready_out(h_ready_out_x[0]),
        .h_resp(h_resp_x[0])
    );
    
    
    AHB_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .HBURST_WIDTH(HBURST_WIDTH),
        .OFFSET(2048),
        .HPROT_WIDTH(HPROT_WIDTH)
    ) slv_1(
        .h_clk(h_clk),
        .h_resetn(h_resetn),
        .h_sel(h_sel_x[1]),
        .h_addr(h_addr),
        .h_burst(h_burst),
        .h_mst_lock(h_mst_lock),
        .h_size(h_size),
        .h_nonsec(h_nonsec),
        .h_trans(h_trans),
        .h_wdata(h_wdata),
        .h_wstrb(h_wstrb),
        .h_write(h_write),
        .h_rdata(h_rdata_x[1]),
        .h_ready(h_ready_out_mux),
        .h_ready_out(h_ready_out_x[1]),
        .h_resp(h_resp_x[1])
    );
    
    AHB_Slave_Slow #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .OFFSET(4096),
        .HBURST_WIDTH(HBURST_WIDTH),
        .HPROT_WIDTH(HPROT_WIDTH)
    ) slv_2(
        .h_clk(h_clk),
        .h_resetn(h_resetn),
        .h_sel(h_sel_x[2]),
        .h_addr(h_addr),
        .h_burst(h_burst),
        .h_mst_lock(h_mst_lock),
        .h_size(h_size),
        .h_nonsec(h_nonsec),
        .h_trans(h_trans),
        .h_wdata(h_wdata),
        .h_wstrb(h_wstrb),
        .h_write(h_write),
        .h_rdata(h_rdata_x[2]),
        .h_ready(h_ready_out_mux),
        .h_ready_out(h_ready_out_x[2]),
        .h_resp(h_resp_x[2])
    );
    
    AHB_Slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .HBURST_WIDTH(HBURST_WIDTH),
        .OFFSET(6144),
        .HPROT_WIDTH(HPROT_WIDTH)
    ) slv_3(
        .h_clk(h_clk),
        .h_resetn(h_resetn),
        .h_sel(h_sel_x[3]),
        .h_addr(h_addr),
        .h_burst(h_burst),
        .h_mst_lock(h_mst_lock),
        .h_size(h_size),
        .h_nonsec(h_nonsec),
        .h_trans(h_trans),
        .h_wdata(h_wdata),
        .h_wstrb(h_wstrb),
        .h_write(h_write),
        .h_rdata(h_rdata_x[3]),
        .h_ready(h_ready_out_mux),
        .h_ready_out(h_ready_out_x[3]),
        .h_resp(h_resp_x[3])
    );
    
    AHB_Slave_Slow #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .HBURST_WIDTH(HBURST_WIDTH),
        .OFFSET(8192),
        .HPROT_WIDTH(HPROT_WIDTH)
    ) slv_4(
        .h_clk(h_clk),
        .h_resetn(h_resetn),
        .h_sel(h_sel_x[4]),
        .h_addr(h_addr),
        .h_burst(h_burst),
        .h_mst_lock(h_mst_lock),
        .h_size(h_size),
        .h_nonsec(h_nonsec),
        .h_trans(h_trans),
        .h_wdata(h_wdata),
        .h_wstrb(h_wstrb),
        .h_write(h_write),
        .h_rdata(h_rdata_x[4]),
        .h_ready(h_ready_out_mux),
        .h_ready_out(h_ready_out_x[4]),
        .h_resp(h_resp_x[4])
    );
    
    Default_Slave default_slv (
        .h_clk(h_clk), //GLOBAL
        .h_resetn(h_resetn), //GLOBAL
        .h_sel(h_sel_x), //DEC -> SLV
        .h_trans(h_trans), //MST -> SLV
        .h_ready(h_ready_out_mux), //MUX -> SLV
        .h_ready_out(h_ready_out_x[5]), //SLV -> MUX
        .h_resp(h_resp_x[5]) //SLV -> MUX
    );
    
    AHB_Mux #(
        .DATA_WIDTH(DATA_WIDTH)
    ) mux(
        .h_clk(h_clk), //GLOBAL
        .h_resetn(h_resetn), //GLOBAL
        .h_rdata_x(h_rdata_x), //SLVx -> MUX
        .h_sel_x(h_sel_x), //DEC -> SLVx/MUX
        .h_ready_x(h_ready_out_x), //SLVx -> MUX
        .h_resp_x(h_resp_x), //SLVx -> MUX
        .h_rdata(mux_h_rdata), //MUX -> MST
        .h_ready(h_ready_out_mux), //MUX -> MST/SLV
        .h_resp(h_resp) //MUX -> MST    
    );
    
    AHB_Decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dec(
        .h_addr(h_addr), //MST -> DEC
        .h_sel_x(h_sel_x) //DEC -> SLVx/MUX
    );

endmodule