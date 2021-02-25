///////////////////////////////////////////////////////////////////////
// --------------------------------------------------------------------
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
// --------------------------------------------------------------------
// Copyright (c) 2005 - 2011 by Lattice Semiconductor Corporation
// --------------------------------------------------------------------
//
// Permission:
//
// Lattice Semiconductor grants permission to use this code for use
// in synthesis for any Lattice programmable logic product. Other
// use of this code, including the selling or duplication of any
// portion is strictly prohibited.
//
// Disclaimer:
//
// This VHDL or Verilog source code is intended as a design reference
// which illustrates how these types of functions can be implemented.
// It is the user's responsibility to verify their design for
// consistency and functionality through the use of formal
// verification methods. Lattice Semiconductor provides no warranty
// regarding the use or functionality of this code.
//
// --------------------------------------------------------------------
//
// Lattice Semiconductor Corporation
// 5555 NE Moore Court
// Hillsboro, OR 97214
// U.S.A
//
// TEL: 1-800-Lattice (USA and Canada)
// 503-268-8001 (other locations)
//
// web: http://www.latticesemi.com/
// email: techsupport@latticesemi.com
//
// --------------------------------------------------------------------
//
//  Project:     Low Pin Count PCI
//  File:        lpc_sm.v
//  Title:       Low Pin Count State Machine
//  Description: Top level of Low Pin Count PCI Memory Interface
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
// $Log: lpc_sm.v,v $
// Revision 1.0  2007-2-13 Jeremy White: Initial Creation, Modified
//                                       Control and Data Path State Machines
// Revision 1.1  2008-1-10 Laxmi V: Removed MEM Read/Write
// Revision 1.2  2008-1-21 Joseph Hsin: Removed special registers(io_wait and io_rec) inputs
//                                      Removed io_rd_sync_last and io_wr_sync_last states to get zero wait state.
//                                      Simplified FSM code.
// Revision 1.3  2008-1-22 Joseph Hsin: Simplified code again.  The lreset_n will now only reset the state machine.
// Revision 1.4  2008-1-23 Joseph Hsin: Modified coding style to fix the 3 errors reported by HDL Explorer.
// Revision 1.5  2008-2-04            Joseph Hsin: Added addr_hit logic so that the design will response to the LPC host only the registers are accessed.
// --------------------------------------------------------------------

`timescale 1 ns / 1 ps

module LPC_Peri (

   // LPC Interface
   input  wire        lclk         , // Clock
   input  wire        lreset_n     , // Reset - Active Low (Same as PCI Reset)
   input  wire        lframe_n     , // Frame - Active Low
   inout  wire [ 3:0] lad_in       , // Address/Data Bus

   input  wire        addr_hit     ,
   output reg  [ 4:0] current_state,

   input  wire [ 7:0] din          ,
   output reg  [ 7:0] lpc_data_in  ,
   output wire [ 3:0] lpc_data_out ,
   output reg  [15:0] lpc_addr     ,
   output wire        lpc_en       ,
   output wire        io_rden_sm   ,
   output wire        io_wren_sm
);

   //reg  [3:0] LAD;

   wire       sync_en   ;
   wire [3:0] rd_addr_en;
   wire [1:0] wr_data_en;
   wire [1:0] rd_data_en;
   wire       tar_F /*synthesis syn_keep = 1*/;

   wire [4:0] next_state;

   `define IDLE             5'h00
   `define START            5'h01
   `define IO_RD            5'h02
   `define IO_RD_ADDR_LCLK1 5'h03
   `define IO_RD_ADDR_LCLK2 5'h04
   `define IO_RD_ADDR_LCLK3 5'h05
   `define IO_RD_ADDR_LCLK4 5'h06
   `define IO_RD_TAR_LCLK1  5'h07
   `define IO_RD_TAR_LCLK2  5'h08
   `define IO_RD_SYNC       5'h09
   `define IO_RD_DATA_LCLK1 5'h0B
   `define IO_RD_DATA_LCLK2 5'h0C
   `define IO_WR            5'h0D
   `define IO_WR_ADDR_LCLK1 5'h0E
   `define IO_WR_ADDR_LCLK2 5'h0F
   `define IO_WR_ADDR_LCLK3 5'h10
   `define IO_WR_ADDR_LCLK4 5'h11
   `define IO_WR_DATA_LCLK1 5'h12
   `define IO_WR_DATA_LCLK2 5'h13
   `define IO_WR_TAR_LCLK1  5'h14
   `define IO_WR_TAR_LCLK2  5'h15
   `define IO_WR_SYNC       5'h16
   `define LAST_TAR_LCLK1   5'h18
   `define LAST_TAR_LCLK2   5'h19

// --------------------------------------------------------------------------
// FSM -- state machine supporting LPC I/O read & I/O write only
// --------------------------------------------------------------------------

always @ (posedge lclk or negedge lreset_n) begin
   if (~lreset_n) current_state <= `IDLE;
   else current_state <= next_state;
end

assign next_state = (lreset_n == 1'b0) ? `IDLE :
                    ((current_state == `IDLE ) && (lframe_n == 1'b0) && (lad_in == 4'h0)) ? `START :
                    ((current_state == `START) && (lframe_n == 1'b0) && (lad_in == 4'h0)) ? `START :
                    ((current_state == `START) && (lframe_n == 1'b1) && (lad_in == 4'h0)) ? `IO_RD :
                    ((current_state == `START) && (lframe_n == 1'b1) && (lad_in == 4'h2)) ? `IO_WR :
                    (lframe_n == 1'b0) ? `IDLE :
                    (current_state == `IO_RD           ) ? `IO_RD_ADDR_LCLK1 :
                    (current_state == `IO_RD_ADDR_LCLK1) ? `IO_RD_ADDR_LCLK2 :
                    (current_state == `IO_RD_ADDR_LCLK2) ? `IO_RD_ADDR_LCLK3 :
                    (current_state == `IO_RD_ADDR_LCLK3) ? `IO_RD_ADDR_LCLK4 :
                    (current_state == `IO_RD_ADDR_LCLK4) ? `IO_RD_TAR_LCLK1  :
                    (current_state == `IO_RD_TAR_LCLK1 ) ? `IO_RD_TAR_LCLK2  :
                    ((current_state == `IO_RD_TAR_LCLK2 ) && (addr_hit == 1'b0))? `IDLE       :
                    ((current_state == `IO_RD_TAR_LCLK2 ) && (addr_hit == 1'b1))? `IO_RD_SYNC :
                    (current_state == `IO_RD_SYNC      ) ? `IO_RD_DATA_LCLK1 :
                    (current_state == `IO_RD_DATA_LCLK1) ? `IO_RD_DATA_LCLK2 :
                    (current_state == `IO_RD_DATA_LCLK2) ? `LAST_TAR_LCLK1   :
                    (current_state == `IO_WR           ) ? `IO_WR_ADDR_LCLK1 :
                    (current_state == `IO_WR_ADDR_LCLK1) ? `IO_WR_ADDR_LCLK2 :
                    (current_state == `IO_WR_ADDR_LCLK2) ? `IO_WR_ADDR_LCLK3 :
                    (current_state == `IO_WR_ADDR_LCLK3) ? `IO_WR_ADDR_LCLK4 :
                    (current_state == `IO_WR_ADDR_LCLK4) ? `IO_WR_DATA_LCLK1 :
                    (current_state == `IO_WR_DATA_LCLK1) ? `IO_WR_DATA_LCLK2 :
                    (current_state == `IO_WR_DATA_LCLK2) ? `IO_WR_TAR_LCLK1  :
                    (current_state == `IO_WR_TAR_LCLK1 ) ? `IO_WR_TAR_LCLK2  :
                    ((current_state == `IO_WR_TAR_LCLK2 ) && (addr_hit == 1'b0))? `IDLE       :
                    ((current_state == `IO_WR_TAR_LCLK2 ) && (addr_hit == 1'b1))? `IO_WR_SYNC :
                    (current_state == `IO_WR_SYNC      ) ? `LAST_TAR_LCLK1   :
                    (current_state == `LAST_TAR_LCLK1  ) ? `LAST_TAR_LCLK2   :
                    `IDLE;

// -------------------------------------------------------------------------
// FSM output logic - Control state machine - LPC I/O read & I/O write only
// -------------------------------------------------------------------------

assign tar_F = (next_state == `LAST_TAR_LCLK1) ? 1'b1 : 1'b0;

assign rd_addr_en = (next_state == `IO_RD_ADDR_LCLK1) ? 4'b1000 :
                    (next_state == `IO_RD_ADDR_LCLK2) ? 4'b0100 :
                    (next_state == `IO_RD_ADDR_LCLK3) ? 4'b0010 :
                    (next_state == `IO_RD_ADDR_LCLK4) ? 4'b0001 :
                    (next_state == `IO_WR_ADDR_LCLK1) ? 4'b1000 :
                    (next_state == `IO_WR_ADDR_LCLK2) ? 4'b0100 :
                    (next_state == `IO_WR_ADDR_LCLK3) ? 4'b0010 :
                    (next_state == `IO_WR_ADDR_LCLK4) ? 4'b0001 :
                    4'b0000;

assign sync_en = (next_state == `IO_RD_SYNC) ? 1'b1 :
                 (next_state == `IO_WR_SYNC) ? 1'b1 :
                 1'b0;

assign rd_data_en = (next_state == `IO_RD_DATA_LCLK1) ? 2'b01 :
                    (next_state == `IO_RD_DATA_LCLK2) ? 2'b10 :
                    2'b00;

assign wr_data_en = (next_state == `IO_WR_DATA_LCLK1) ? 2'b01 :
                    (next_state == `IO_WR_DATA_LCLK2) ? 2'b10 :
                    2'b00;

assign io_rden_sm = (next_state == `IO_RD_TAR_LCLK1) ? 1'b1 :
                    (next_state == `IO_RD_TAR_LCLK2) ? 1'b1 :
                    1'b0;

assign io_wren_sm = (next_state == `IO_WR_TAR_LCLK1) ? 1'b1 :
                    (next_state == `IO_WR_TAR_LCLK2) ? 1'b1 :
                    1'b0;

// Register LPC Address

always @ (posedge lclk) begin
	if (rd_addr_en[3] == 1'b1) lpc_addr[15:12] <= lad_in;
	if (rd_addr_en[2] == 1'b1) lpc_addr[11:8] <= lad_in;
	if (rd_addr_en[1] == 1'b1) lpc_addr[7:4] <= lad_in;
	if (rd_addr_en[0] == 1'b1) lpc_addr[3:0] <= lad_in;
end

/* Original code from Lattice : creates latches, not FPGA-friendly !
assign lpc_addr[15:12] = (rd_addr_en[3] == 1'b1) ? lad_in : lpc_addr[15:12];
assign lpc_addr[11: 8] = (rd_addr_en[2] == 1'b1) ? lad_in : lpc_addr[11: 8];
assign lpc_addr[ 7: 4] = (rd_addr_en[1] == 1'b1) ? lad_in : lpc_addr[ 7: 4];
assign lpc_addr[ 3: 0] = (rd_addr_en[0] == 1'b1) ? lad_in : lpc_addr[ 3: 0];
*/

//Register Data In

always @ (posedge lclk) begin
   if (wr_data_en[0]) lpc_data_in[3:0] <= lad_in;
   if (wr_data_en[1]) lpc_data_in[7:4] <= lad_in;
   //LAD = (current_state == `IO_WR_SYNC) ? 4'b0000 : 4'bzzzz; // On the beginning of write sync, it should be assigned to 'sync success' (0)
end

assign lad_in = (current_state == `IO_WR_SYNC) ? 4'b0000 : 4'bzzzz;
assign lad_in = (rd_data_en[0]) ? lpc_data_out: 4'bzzzz;
assign lad_in = (rd_data_en[1]) ? lpc_data_out: 4'bzzzz;


// Read Back-side Data to LPC


assign lpc_data_out = (sync_en == 1'b1      ) ? 4'h0     :
                      (tar_F == 1'b1        ) ? 4'hF     :
                      (lframe_n == 1'b0     ) ? 4'h0     :  
                      (rd_data_en[0] == 1'b1) ? din[3:0] :
                      (rd_data_en[1] == 1'b1) ? din[7:4] :
                      4'h0;



assign lpc_en = (sync_en == 1'b1      ) ? 1'h1 :
                (tar_F == 1'b1        ) ? 1'h1 :
                (lframe_n == 1'b0     ) ? 1'h0 :  
                (rd_data_en[0] == 1'b1) ? 1'b1 :
                (rd_data_en[1] == 1'b1) ? 1'b1 :
                1'h0;

endmodule
