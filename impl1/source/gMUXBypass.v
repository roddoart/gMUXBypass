module gMUXBypass #(
	parameter USE_PWM = 0
)(

	// LVDS input
	input	[2:0]	LVDS_IG_A_DATA	,
	
	input	[2:0]	LVDS_IG_B_DATA	,

	input	LVDS_IG_A_CLK			,
	
	// Panel control signals input
	input	LVDS_IG_BKL_ON			,
	input	LVDS_IG_PANEL_PWR		,
	
	// LVDS output
	output	[2:0]	LVDS_A_DATA		,
	
	output	[2:0]	LVDS_B_DATA		,
	
	output	LVDS_A_CLK				,
	output	LVDS_B_CLK				,
	
	// Panel control signals output
	output	LCD_BKLT_EN				,
	output	LCD_PWR_EN				,
	output	LCD_BKLT_PWM			,
	
	// dGPU power enable and reset
	output	P3V3GPU_EN				,
	output	P1V5FB1V8GPU_R_EN		,
	output	P1V0GPU_EN				,
	output	GPUVCORE_EN				,
	output	EG_RESET_L				,
	
	// DDC signals
	output	LVDS_DDC_SEL_IG			,
	output	LVDS_DDC_SEL_EG ,

	/////////////////
	/// Modifications by Romain to implement PWM generation ///
	// Clock input
	input	LPC_CLK33M_GMUX ,
	// Button input
	input	GMUX_PL6A,
	
	/// LPC IO PORT
	inout	[3:0]	LPC_AD ,
	input	LPC_FRAME_L,
	input	LPCPLUS_RESET_L
	/////////////////
);

	assign LVDS_A_DATA[2:0] = LVDS_IG_A_DATA[2:0];

	assign LVDS_B_DATA[2:0] = LVDS_IG_B_DATA[2:0];
	
	assign LVDS_A_CLK	= LVDS_IG_A_CLK;
	
	assign LVDS_B_CLK	= LVDS_IG_A_CLK;
	
	// Pass through panel control signals
	assign LCD_BKLT_EN	= LVDS_IG_BKL_ON;
	assign LCD_PWR_EN	= LVDS_IG_PANEL_PWR;
	
	// Disable dGPU rails and hold in reset
	assign P3V3GPU_EN			= 0;
	assign P1V5FB1V8GPU_R_EN	= 0;
	assign P1V0GPU_EN			= 0;
	assign GPUVCORE_EN			= 0;
	assign EG_RESET_L			= 0;
	
	// Display Config Channel MUX select
	assign LVDS_DDC_SEL_IG		= 1;
	assign LVDS_DDC_SEL_EG		= 0;
	
	/////////////////
	/// Modifications by Romain to implement an LPC Interface
	
	// Reset values for backlight and max_backlight
	reg [31:0] backlight='d49949; //reset value for the backlight : 35% duty clycle
	reg [31:0] max_backlight ='d142711; //constant value ; get 200Hz PWM freq
	
	wire [15:0] address;
	reg [7:0] data_rd;
	reg [7:0] temp;
	wire [7:0] data_wr;
	wire rd_en;
	wire wr_en;
	
	//clock_button : clock used to filter the button
	//  Spec target 2 Hz (half second press)
	//  Use 33Mhz divided by 2e24 gives 1.96 Hz
	reg[27:0] counter=0;
	reg clock_button=1'b0;
	parameter CNTMAX = 'hffffff;

	always @(posedge LPC_CLK33M_GMUX)
	begin
	 counter <= counter + 1;
	 if(counter>=(CNTMAX-1))
	   counter <= 'h0;
	 clock_button <= counter[23] ; // ~2Hz
	end
	
	//Button capture : 
	reg [4:0] duty_cycle = 'd11; //17-values backlight, reset at level 10, zero ignored
	wire button_pressed ;
	reg button_pressed_d = 1'b0;
	wire button_event ;
	
	// Create button event @33MHz, with auto-repeat @2Hz
	assign button_pressed = (!GMUX_PL6A & clock_button) ;
	always @(posedge LPC_CLK33M_GMUX)
	begin
		button_pressed_d <= button_pressed ;
	end
	assign button_event = (button_pressed && !button_pressed_d)?1:0 ;
	
	// Duty cycle loop : create the rolling 16-state backlight loop
	always @(posedge clock_button)
	 begin
	  if (GMUX_PL6A==1'b0)
	    begin
		duty_cycle <= duty_cycle +1;
		if(duty_cycle>='d16)
		  duty_cycle <='d1; //I ignore the '0' setting because I don't like the fully black screen
	    end //if
	  end //always
	
	// LPC peripheral
	LPC_Peri IOPORT(
	.lclk (LPC_CLK33M_GMUX), 
	.lreset_n (LPCPLUS_RESET_L), 
    .lframe_n (LPC_FRAME_L), 
    .lad_in (LPC_AD), 
    .addr_hit(1'b1),
    .current_state(),
    .din(data_rd),
    .lpc_data_in(data_wr),
    .lpc_data_out(),
    .lpc_addr(address),
    .lpc_en(),
    .io_rden_sm(rd_en),
    .io_wren_sm(wr_en)
	);

	always @(posedge LPC_CLK33M_GMUX)
	begin
	/// LPC Write Operation
	/// BACKLIGHT Register, Address 0x0774, 0x0775, 0x0776, 0x0777
	/// MAX_BACKLIGHT Register, Address 0x0770, 0x0771, 0x0772, 0x0773
		if (wr_en)	begin
		case(address)
				//'h0770 : max_backlight[7:0] <= data_wr ;
				//'h0771 : max_backlight[15:8] <= data_wr ;
				//'h0772 : max_backlight[23:16] <= data_wr ;
				//'h0773 : max_backlight[31:24] <= data_wr ;
				'h0774 : backlight[7:0] <= data_wr ;
				'h0775 : backlight[15:8] <= data_wr ;
				'h0776 : backlight[23:16] <= data_wr ;
				'h0777 : backlight[31:24] <= data_wr ;
				default : ;
		endcase
		end //if wr_en
	/// BIL Button write operation
	/// Use 16 pre-defined values, obtained by retro-engineering of the PWM signal from a 13" MBP 2011
		if (button_event) begin
		case (duty_cycle)
			'd1 : backlight <= 'd2854 ;
			'd2 : backlight <= 'd4281 ;
			'd3 : backlight <= 'd5708 ;
			'd4 : backlight <= 'd8563 ;
			'd5 : backlight <= 'd11417 ;
			'd6 : backlight <= 'd15698 ;
			'd7 : backlight <= 'd19980 ;
			'd8 : backlight <= 'd25688 ;
			'd9 : backlight <= 'd34251 ;
			'd10 : backlight <= 'd41386 ;
			'd11 : backlight <= 'd49949 ;
			'd12 : backlight <= 'd59939 ;
			'd13 : backlight <= 'd72783 ;
			'd14 : backlight <= 'd87054 ;
			'd15 : backlight <= 'd105606 ;
			'd16 : backlight <= 'd127013 ;	
			default : ;
		endcase
		end //if button_event
	end // always
	
	always @(posedge LPC_CLK33M_GMUX)
	begin
	/// LPC Read Operation
	/// BACKLIGHT Register, Address 0x0774, 0x0775, 0x0776, 0x0777
	/// MAX_BACKLIGHT Register, Address 0x0770, 0x0771, 0x0772, 0x0773
	/// MAJOR_VERSION Register, Address 0x704
	/// MINOR_VERSION Register, Address 0x705
	/// RELEASE_VERSION Register, Address 0x706
	
		if (rd_en)	begin
		case(address)
				'h0704 : data_rd <= 'd1;
				'h0705 : data_rd <= 'd9;
				'h0706 : data_rd <= 'd36;
				'h0770 : data_rd <= max_backlight[7:0];
				'h0771 : data_rd <= max_backlight[15:8];
				'h0772 : data_rd <= max_backlight[23:16];
				'h0773 : data_rd <= max_backlight[31:24];
				'h0774 : data_rd <= backlight[7:0];
				'h0775 : data_rd <= backlight[15:8];
				'h0776 : data_rd <= backlight[23:16];
				'h0777 : data_rd <= backlight[31:24];
				default : data_rd <= 'h0;
		endcase
		end
	end
	
	
	// The target frequency for the PWM waveform is 550 Hz
	// The current frequency obtained is ~200Hz with a counter based on 33MHz
	//  couting up to MAX_BRIGHTNESS (142711)
	// This could be improved by manipulation the backlight and max_backlight registers before generating the PWM
	// The BRIGHTNESS value will directly set the duty cycle
	
	reg[16:0] counter_PWM = 0;
	always @(posedge LPC_CLK33M_GMUX)
	 begin
	   counter_PWM <= counter_PWM + 1;
	   if(counter_PWM>=max_backlight) 
		counter_PWM <= 0;
	  end
	
	assign LCD_BKLT_PWM = (counter_PWM<backlight) ? 1:0 ;		
	/////////////////

generate
	// If PWM mod wire isn't installed
	if (!USE_PWM) begin
		//assign LCD_BKLT_PWM = 1;

	end

endgenerate
endmodule