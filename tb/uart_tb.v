`timescale 1ns / 1ps

module uart_tb();
    
reg clk;
reg rst;

wire rxd;
wire txd;

reg [31:0] awaddr;
reg awvalid;
wire awready;

reg [31:0] wdata;
reg [3:0] wstrb;
reg wvalid;
wire wready;

wire [1:0] bresp;
wire bvalid;
reg bready;

reg [31:0] araddr;
reg arvalid;
wire arready;

wire [31:0] rdata;
wire [1:0] rresp;
wire rvalid;
reg rready;

axi_lite_uart dut (
    .clk(clk),
    .rst(rst),
    .rxd(rxd),
    .txd(txd),
    .awaddr(awaddr),
    .awvalid(awvalid),
    .awready(awready),
    .wdata(wdata),
    .wstrb(wstrb),
    .wvalid(wvalid),
    .wready(wready),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready),
    .araddr(araddr),
    .arvalid(arvalid),
    .arready(arready),
    .rdata(rdata),
    .rresp(rresp),
    .rvalid(rvalid),
    .rready(rready)
);

assign rxd = txd;

initial begin   
    clk = 0;
    rst = 1;
    awvalid = 0;
    wvalid = 0;
    bready = 0;
    arvalid = 0;
    rready = 0;
    
    repeat(100)begin
        @ (posedge clk) ;
    end
    
    rst = 0;
    
    repeat(100)begin
        @ (posedge clk) ;
    end
    
    awvalid = 1;
    awaddr = 4;
    
    while(awready == 0)
        @ (posedge clk) ;
        
    #1 awvalid = 0;
    
    
    
    wvalid = 1;
    wdata = 8'h30;
    
    while(wready == 0)
        @ (posedge clk) ;
        
    #1 wvalid = 0;
    
    
    
    bready = 1;    
    
    while(bvalid == 0)
        @ (posedge clk) ;
        
    #1 bready = 0;
    
end

always
    #10 clk = ~clk;

endmodule
