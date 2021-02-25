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
// Code Revision History :
// --------------------------------------------------------------------
// Ver: | Author |Mod. Date |Changes Made:
// V0.5 | MR     |01/20/09  |Initial ver
// V1.0 | MR     |02/09/09  |Clean up comments
//
// --------------------------------------------------------------------
`timescale 1ns/1ps


module lpc_peri_tb();
reg  		addr_hit;
reg  		IO_Read_Flag  , IO_Write_Flag;   //control: current host read/write operation
reg  		LCLK_in, LRESET_in, LFRAME_in;
reg  [15:0] Host_Address_in;          //Address to input to the LPC host
reg  [ 7:0] Host_Write_in;
reg  [ 7:0] Peri_Data_in;

wire [ 7:0] Peri_Write_out;
wire [15:0] Peri_Address_out;         //Address received by LPC peripheral
wire [ 7:0] Host_Data_out;
wire [ 3:0] Peri_Read_out;
wire 		Host_Ready;
wire 		IO_Read_Status, IO_Write_Status; //status: current peripheral read/write operation
wire [4:0] 	current_peri_state;        //status: current peripheral state
wire [4:0] 	current_host_state;        //status: current host state
wire 		peri_en;                         //status: peripheral is enabled

wire 		LCLK,LRESET,LFRAME;
wire [3:0] 	LAD;

parameter DELAY = 700000000; //0,7s
reg button ;

initial
begin
//#1;
  	LCLK_in = 1'b1;
  	forever
    	#20 LCLK_in = ~LCLK_in;
end

//always
initial
begin
button=1'b1;
#DELAY button=1'b0;
//#DELAY button=1'b1;
end

initial
begin
	// Initialize
  	LFRAME_in      = 1;
  	addr_hit       = 1;
  	LRESET_in      = 1;
  	IO_Read_Flag   = 0;
  	IO_Write_Flag  = 1;
  	#40 LRESET_in  = 0;
  	#250 LRESET_in = 1;

	#10000000
	// Perform read - MAX_BACKLIGHT
	Host_Address_in = 16'h0770;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0771;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0772;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0773;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	
	#800 
	// Perform write - BACKLIGHT
	// Value 85620d = 0x00014e74 = 77% duty cycle
	IO_Read_Flag   = 0;
  	IO_Write_Flag  = 1;
  	#40  LFRAME_in  = 0;
  	Host_Address_in = 16'h0774;
  	Host_Write_in   = 8'h74;
  	#40  LFRAME_in  = 1;
	#800  LFRAME_in  = 0;
  	Host_Address_in = 16'h0775;
  	Host_Write_in   = 8'h4e;
  	#40  LFRAME_in  = 1;
	#800  LFRAME_in  = 0;
  	Host_Address_in = 16'h0776;
  	Host_Write_in   = 8'h01;
  	#40  LFRAME_in  = 1;
	#800  LFRAME_in  = 0;
  	Host_Address_in = 16'h0777;
  	Host_Write_in   = 8'h00;
  	#40  LFRAME_in  = 1;
	
	#800 
	// Perform read - BACKLIGHT
	Host_Address_in = 16'h0777;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0776;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0775;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0774;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 

	// Perform read - VERSIONS
	Host_Address_in = 16'h0704;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0705;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0706;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 Host_Address_in = 16'h0704;
  	LFRAME_in      = 0;
    IO_Read_Flag   = 1;
    IO_Write_Flag  = 0;
  	#80  LFRAME_in      = 1;
	#800 
	
  	#1000;
	//  $stop;
end

LPC_Host lpc_host_inst(
.LCLK_in(LCLK_in),
   // Input from GPIO
.Address(Host_Address_in),
.Data_in(Host_Write_in),
.LRESET_in(LRESET_in),
.LFRAME_in(LFRAME_in),
.IO_Read_Status(IO_Read_Flag),
.IO_Write_Status(IO_Write_Flag),
   // Output to GPIO
.Data_out(Host_Data_out),
.Ready(Host_Ready),
   // LPC Host Interface
.LAD(LAD), .LCLK(LCLK), .LRESET(LRESET), .LFRAME(LFRAME),
.host_state_out(current_host_state)
);

//***************************
// Peripheral instantiation
//***************************
//  LPC_Peri lpc_peri_inst(
   // LPC Interface
//  .lclk(LCLK), .lreset_n(LRESET), .lframe_n(LFRAME), .lad_in(LAD),
//  .addr_hit(addr_hit),
//  .current_state(current_peri_state),
//  .din(Peri_Data_in),
//  .lpc_data_in(Peri_Write_out),
//  .lpc_data_out(Peri_Read_out),
//  .lpc_addr(Peri_Address_out),
//  .lpc_en(peri_en),
//  .io_rden_sm(IO_Read_Status), .io_wren_sm(IO_Write_Status)
//  );

gMUXBypass GMUX (
.LVDS_IG_A_DATA(), 
.LVDS_IG_B_DATA(), 
.LVDS_IG_A_CLK(), 
.LVDS_IG_BKL_ON(),
.LVDS_IG_PANEL_PWR(),
.LVDS_A_DATA(), 
.LVDS_B_DATA(),
.LVDS_A_CLK(),
.LVDS_B_CLK(),
.LCD_BKLT_EN(), 
.LCD_PWR_EN(),
.LCD_BKLT_PWM(),
.P3V3GPU_EN(),
.P1V5FB1V8GPU_R_EN(), 
.P1V0GPU_EN(),
.GPUVCORE_EN(),
.EG_RESET_L(),
.LVDS_DDC_SEL_IG(), 
.LVDS_DDC_SEL_EG(),
.LPC_CLK33M_GMUX (LCLK),
.GMUX_PL6A (button),
.LPC_AD(LAD),
.LPCPLUS_RESET_L(LRESET),
.LPC_FRAME_L(LFRAME)
);

endmodule

module LPC_Host (
   input  wire        LCLK_in,
   // Input from GPIO
   input  wire [15:0] Address,
   input  wire [ 7:0] Data_in,
   input  wire        LRESET_in,
   input  wire        LFRAME_in,
   input  wire        IO_Read_Status,
   input  wire        IO_Write_Status,
   // Output to GPIO
   output reg  [ 7:0] Data_out,
   output reg         Ready,
   // LPC Host Interface
   inout  wire [ 3:0] LAD,
   output wire        LCLK,
   output reg         LRESET,
   output reg         LFRAME,
   output wire [ 4:0] host_state_out
);

   // LPC Host State Variable
   reg [4:0] host_state;

   // Define intermediate signals
   reg       LAD_En;
   reg [3:0] LAD_Out;
   reg [3:0] LAD_reg;

   assign host_state_out = host_state;

   assign LAD  = (LAD_En) ? LAD_Out : 4'bZZZZ;
   assign LCLK = ~LCLK_in;

   // LPC Host State Definitions
   parameter
     //used by both
     force_reset  = 5'h00,
     idle         = 5'h01,
     start        = 5'h02,

     //if read = true
     ior_cyc_type = 5'h03,
     rd_addr1     = 5'h04,
     rd_addr2     = 5'h05,
     rd_addr3     = 5'h06,
     rd_addr4     = 5'h07,
     rd_tar1      = 5'h08,
     rd_tar2      = 5'h09,
     rd_sync      = 5'h0A,
     rd_data1     = 5'h0B,
     rd_data2     = 5'h0C,

     //if write = true
     iow_cyc_type = 5'h0D,
     wr_addr1     = 5'h0E,
     wr_addr2     = 5'h0F,
     wr_addr3     = 5'h10,
     wr_addr4     = 5'h11,
     wr_data1     = 5'h12,
     wr_data2     = 5'h13,
     wr_tar1      = 5'h14,
     wr_tar2      = 5'h15,
     wr_sync      = 5'h16,

     //used by both
     final_tar1   = 5'h17,
     final_tar2   = 5'h18;

   always @ (posedge LCLK_in)
   begin
   	  LAD_reg <= LAD;
      case (host_state)
         force_reset:
            if (~LRESET_in) begin
               LRESET  = 0;
               LFRAME  = 1;
               LAD_En  = 0;
               LAD_Out = 4'b0000;
               Ready   = 0;
            end
            else begin 
               LRESET  = 1;
               LFRAME  = 1;
               LAD_En  = 0;
               LAD_Out = 4'b0000;
               Ready   = 0;
               host_state = idle;
            end
         idle:
            if (~LFRAME_in) begin
               LFRAME  = 0;
               LAD_En  = 1;
               LAD_Out = 4'b0000;
               Ready   = 0;
               host_state = start;
            end
            else LRESET = 1;
         start:
            if (LFRAME_in & IO_Read_Status) begin
               LFRAME  = 1;
               LAD_Out = 4'b0000;
               host_state = ior_cyc_type;
            end
            else if (LFRAME_in & IO_Write_Status) begin
               LFRAME  = 1;
               LAD_Out = 4'b0010;
               host_state = iow_cyc_type;
            end
         ior_cyc_type:
            begin
               LAD_Out    = Address[15:12];
               host_state = rd_addr1;
            end
         rd_addr1:
            begin
               LAD_Out    = Address[11: 8];
               host_state = rd_addr2;
            end
         rd_addr2:
            begin
               LAD_Out    = Address[ 7: 4];
               host_state = rd_addr3;
            end
         rd_addr3:
            begin
               LAD_Out    = Address[ 3: 0];
               host_state = rd_addr4;
            end
         rd_addr4:
            begin
               LAD_Out    = 4'b1111;
               host_state = rd_tar1;
            end
         rd_tar1:
            begin
               LAD_En     = 0;
               host_state = rd_tar2;
            end
         rd_tar2:
            begin
               host_state = rd_sync;
            end
         rd_sync:
            begin
               Data_out[3:0] = LAD;
               host_state    = rd_data1;
               if (LAD_reg == 4'b0000) host_state = rd_data1;
               else if ((LAD_reg != 4'b0101) && (LAD_reg != 4'b0110)) begin
                  LRESET     = 0;
                  LFRAME     = 1;
                  LAD_En     = 0;
                  LAD_Out    = 4'b0000;
                  Ready      = 0;
                  host_state = force_reset;
               end
            end
         rd_data1:
            begin
               Data_out[7:4] = LAD;
               host_state    = rd_data2;
            end
         rd_data2:
            begin
               host_state = final_tar1;
            end
         iow_cyc_type:
            begin
               LAD_Out    = Address[15:12];
               host_state = wr_addr1;
            end
         wr_addr1:
            begin
               LAD_Out    = Address[11: 8];
               host_state = wr_addr2;
            end
         wr_addr2:
            begin
               LAD_Out    = Address[ 7: 4];
               host_state = wr_addr3;
            end
         wr_addr3:
            begin
               LAD_Out    = Address[ 3: 0];
               host_state = wr_addr4;
            end
         wr_addr4:
            begin
               LAD_Out    = Data_in[3:0];
               host_state = wr_data1;
            end
         wr_data1:
            begin
               LAD_Out    = Data_in[7:4];
               host_state = wr_data2;
            end
         wr_data2:
            begin
               LAD_Out    = 4'b1111;
               host_state = wr_tar1;
            end
         wr_tar1:
            begin
               LAD_En     = 0;
               host_state = wr_tar2;
            end
         wr_tar2:
            begin
               host_state = wr_sync;
            end
         wr_sync:
            if (LAD_reg == 4'b0000) host_state = final_tar1;
            else if ((LAD_reg != 4'b0101) && (LAD_reg != 4'b0110)) begin
               LRESET  = 0;
               LFRAME  = 1;
               LAD_En  = 0;
               LAD_Out = 4'b0000;
               Ready   = 0;
               host_state = force_reset;
            end
         final_tar1:
            if (LAD_reg != 4'b1111) begin
               LRESET  = 0;
               LFRAME  = 1;
               LAD_En  = 0;
               LAD_Out = 4'b0000;
               Ready   = 0;
               host_state = force_reset;
            end
            else begin
               Ready = 1;
               host_state = final_tar2;
            end
         final_tar2:
            begin
               host_state = idle;
            end
         default:
            host_state    = force_reset;
      endcase
   end

endmodule

module BI_DIR (O,I0,IO,OE);
input I0,OE;
inout IO;
output O;

supply0 GND;
supply1 VCC;

reg IO0, O0;
wire IO1;

parameter PULL = "Off";
parameter OUTOPEN = "Off";

//assign O=O0;
buf INSXQ1 (O,O0);
//assign IO = IO0;
//buf INSXQ2 (IO,IO0);
//assign IO1 = IO;
buf INSXQ3 (IO1,IO);
bufif1 INSXQ2 (IO,IO0,OE);
always @(IO1)
begin
 if (PULL == "Off")
        case(IO1)
           1'b0: O0 = 1'b0;
           1'b1: O0 = 1'b1;
           1'bz: O0 = 1'bx;
           1'bx: O0 = 1'bx;
        endcase
 else if (PULL == "Up")
        case(IO1)
           1'b0: O0 = 1'b0;
           1'b1: O0 = 1'b1;
           1'bz: O0 = 1'b1;
        endcase
 else if (PULL == "Down")
        case(IO1)
           1'b0: O0 = 1'b0;
           1'b1: O0 = 1'b1;
           1'bz: O0 = 1'b0;
        endcase
 else if (PULL == "Hold")
        case(IO1)
           1'b0: O0 = 1'b0;
           1'b1: O0 = 1'b1;
           1'bz: O0 = O0;
        endcase
end


always @(OE or I0)
  begin
     if (OE == 1'b0)
         IO0 = 1'bz;
     else if (OE == 1'b1)
            if (OUTOPEN == "Off")
               case(I0)
                 1'b0: IO0 = 1'b0;
                 1'b1: IO0 = 1'b1;
                 1'bz: IO0 = 1'bx;
                 1'bx: IO0 = 1'bx;
               endcase
            else if (OUTOPEN == "Drain" || OUTOPEN == "Collect")
               begin
                 if (I0 == 1'b0)
                    IO0 = 1'b0;
                 else if (I0 == 1'b1)
                   begin
                     if (PULL == "Off")
                       IO0 = 1'bz;
                     else if (PULL == "Up")
                       IO0 = 1'b1;
                     else if (PULL == "Down")
                       IO0 = 1'b0;
                     else if (PULL == "Hold")
                       IO0 = IO0;
                     else
                       IO0 = 1'bz;
                   end
                 else
                    IO0 = 1'bx;
          end
  end


specify

(I0 => IO) = 0:0:0, 0:0:0;
(OE => IO) = 0:0:0, 0:0:0;
(IO => O) =  0:0:0, 0:0:0;

endspecify


endmodule