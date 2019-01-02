`timescale 1ns / 1ps

module axi_lite_uart
(
	input wire clk,
	input wire rst,

	input wire rxd,
	output wire txd,

	input wire [31:0] awaddr,
	input wire awvalid,
	output wire awready,

	input wire [31:0] wdata,
	input wire [3:0] wstrb,
	input wire wvalid,
	output wire wready,

	output wire [1:0] bresp,
	output wire bvalid,
	input wire bready,

	input wire [31:0] araddr,
	input wire arvalid,
	output wire arready,

	output wire [31:0] rdata,
	output wire [1:0] rresp,
	output wire rvalid,
	input wire rready
);

wire uart_rst;

reg [7:0] uart_wdata;
reg uart_wvalid;
wire uart_wready;

wire uart_rdata;
wire uart_rvalid;
reg uart_rready;

wire tx_busy;
wire rx_busy;
wire rx_overrun;
wire rx_frame_err;

reg [15:0] ctl_prescaler;
reg ctl_rst;
reg ctl_rxe;
wire [4:0] ctl_status;

reg awready_r;
reg wready_r;
reg bvalid_r;
reg arready_r;
reg rvalid_r;
reg [31:0] rdata_r;

reg [1:0] write_addr;
reg [1:0] read_addr;

reg [31:0] ram_r;
reg [7:0] uart_rdata_r;

reg uart_send;
reg uart_read;

assign uart_rst = rst | ctl_rst;

assign bresp = 0;
assign rresp = 0;

assign awready = awready_r;
assign wready = wready_r;
assign bvalid = bvalid_r;
assign arready = arready_r;
assign rvalid = rvalid_r;
assign rdata = rdata_r;

assign ctl_status[0] = tx_busy;
assign ctl_status[1] = rx_busy;
assign ctl_status[2] = rx_overrun;
assign ctl_status[3] = rx_frame_err;
assign ctl_status[4] = ctl_rxe;

always @ (posedge clk) begin : axi_aw
	reg enable;
	if (rst) begin
		write_addr <= 0;
		awready_r <= 0;
		enable <= 1;
	end else begin
		if (enable && awvalid) begin
			enable <= 0;
			awready_r <= 1;
		end

		if (awready_r && awvalid) begin
			awready_r <= 0;
			write_addr <= awaddr[3:2];
		end

		if (bvalid_r && bready) begin
			enable <= 1;
		end
	end
end

always @ (posedge clk) begin : axi_w
	reg enable;
	if (rst) begin
		wready_r <= 0;
		enable <= 1;

		ctl_rst <= 1;
		ctl_prescaler <= 0;
		uart_send <= 0;
		uart_wdata <= 0;
		ram_r <= 0;

	end else begin
		uart_send <= 0;
		if (enable && wvalid) begin
			enable <= 0;
			wready_r <= 1;
		end

		if (wready_r && wvalid) begin
			wready_r <= 0;
			case (write_addr)
				0: begin
					ctl_rst <= wdata[0];
				end
				1: begin
					ctl_prescaler <= wdata[15:0];
				end
				2: begin
					uart_send <= 1;
					uart_wdata <= wdata[7:0];
				end
				3: begin
					ram_r <= wdata;
				end
			endcase
		end

		if (bvalid_r && bready) begin
			enable <= 1;
		end
	end
end

always @ (posedge clk) begin : axi_b
	reg enable;
	if (rst) begin
		bvalid_r <= 0;
		enable <= 1;
	end else begin
		if (enable && bready) begin
			enable <= 0;
			bvalid_r <= 1;
		end

		if (bvalid_r && bready) begin
			enable <= 1;
			bvalid_r <= 0;
		end
	end
end

always @ (posedge clk) begin : axi_ar
	reg enable;
	if (rst) begin
		read_addr <= 0;
		arready_r <= 0;
		enable <= 1;
	end else begin
		if (enable && arvalid) begin
			enable <= 0;
			arready_r <= 1;
		end

		if (arready_r && arvalid) begin
			arready_r <= 0;
			read_addr <= araddr[3:2];
		end

		if (rvalid_r && rready) begin
			enable <= 1;
		end
	end
end

always @ (posedge clk) begin : axi_r
	reg enable;
	if (rst) begin
		rvalid_r <= 0;
		rdata_r <= 0;
		uart_read <= 0;
		enable <= 1;
	end else begin
		uart_read <= 0;
		if (enable && rready) begin
			enable <= 0;
			rvalid_r <= 1;
			case (read_addr)
				0: begin
					rdata_r[4:0] <= ctl_status;
				end
				1: begin
					rdata_r[15:0] <= ctl_prescaler;
				end
				2: begin
					uart_read <= 1;
					rdata_r[7:0] <= uart_rdata_r;
				end
				3: begin
					rdata_r <= ram_r;
				end
			endcase
		end

		if (rvalid_r && rready) begin
			rvalid_r <= 0;
			enable <= 1;
		end
	end
end

always @ (posedge clk) begin : uart_w
	reg enable;
	if (uart_rst) begin
		uart_wvalid <= 0;
		enable <= 1;
	end else begin
		if (enable && uart_send) begin
			uart_wvalid <= 1;
			enable <= 0;
		end
		if (uart_wvalid && uart_wready) begin
			enable <= 1;
			uart_wvalid <= 0;
		end
	end
end

always @ (posedge clk) begin : uart_r
	reg enable;
	if (uart_rst) begin
		uart_rready <= 0;
		uart_rdata_r <= 0;
		ctl_rxe <= 1;
		enable <= 1;
	end else begin
		if (enable && uart_read) begin
			ctl_rxe <= 1;
			uart_rready <= 1;
			enable <= 0;
		end
		if (uart_rvalid && uart_rready) begin
			enable <= 1;
			uart_rready <= 0;
			uart_rdata_r <= uart_rdata;
			ctl_rxe <= 0;
		end
	end
end

uart #(
	.DATA_WIDTH(8)
) uart_inst (
	.clk(clk),
	.rst(uart_rst),

	.s_axis_tdata(uart_wdata),
	.s_axis_tvalid(uart_wvalid),
	.s_axis_tready(uart_wready),

	.m_axis_tdata(uart_rdata),
	.m_axis_tvalid(uart_rvalid),
	.m_axis_tready(uart_rready),

	.rxd(rxd),
	.txd(txd),

	.tx_busy(tx_busy),
	.rx_busy(rx_busy),

	.rx_overrun_error(rx_overrun),
	.rx_frame_error(rx_frame_err),

	.prescale(ctl_prescaler)
);

endmodule
