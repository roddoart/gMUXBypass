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

	/// Modifications by Romain to implement PWM generation ///
	// Clock input
	input	LPC_CLK33M_GMUX ,
	// Button input
	input	GMUX_PL6A
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
	
	/// Modifications by Romain to implement PWM generation ///
	//Slow clock generation
	//clock_pwm : clock used to generate the PWM waveform
	//  Spec target around 65 KHz, to obtain 650Hz PWM signal freq
	//  Use 33MHz divided by 2e9 
	//clock_button : clock used to filter the button
	//  Spec target 2 Hz (half second press)
	//  Use 33Mhz divided by 2e24 gives 1.96 Hz
	reg[27:0] counter=0;
		reg clock_pwm=1'b0;
	reg clock_button=1'b0;
	parameter CNTMAX = 'hffffff;

	//Clock generator
	always @(posedge LPC_CLK33M_GMUX)
	begin
	 counter <= counter + 1;
	 if(counter>=(CNTMAX-1))
	   counter <= 'h0;
	 clock_pwm <= counter[8] ; // ~65KHz
	 clock_button <= counter[23] ; // ~2Hz
	end

	//Button capture
	reg [4:0] duty_cycle = 'd10; //17-values backlight, reset at level 10, zero ignored
	always @(posedge clock_button)
	 begin
	  if (GMUX_PL6A==1'b0)
	    begin
		duty_cycle <= duty_cycle +1;
		if(duty_cycle>='d16)
		  duty_cycle <='d1; //I ignore the '0' setting because I don't like the fully black screen
	    end
	  end

	//PWM output
	// 100 time slices to build the PWM directly from the %duty_cycles
	// the duty cycles were scoped on a working 2010 13-inch MBP
	// -----------------------
	// Step		Duty-Cycle (%)
	// ----		--------------
	// 0		0
	// 1		1.77
	// 2		2.88
	// 3		4.26
	// 4		6.09
	// 5		8.3
	// 6		11.11
	// 7		14.5
	// 8		18.6
	// 9		23.7
	// 10		28.9
	// 11		35.1
	// 12		42.4
	// 13		51.16
	// 14		61.77
	// 15		74.22
	// 16		89.1
	// -----------------------
	
	reg[6:0] counter_PWM = 0;
	always @(posedge clock_pwm)
	 begin
	   counter_PWM <= counter_PWM + 1;
	   if(counter_PWM>=99) 
		counter_PWM <= 0;
	  end
	
	assign LCD_BKLT_PWM = (  'b0 &&(duty_cycle=='d0) ||  //ignored by my duty cycle counter
				(counter_PWM<'d2)&&(duty_cycle=='d1) ||
				(counter_PWM<'d3)&&(duty_cycle=='d2) ||
				(counter_PWM<'d4)&&(duty_cycle=='d3) ||
				(counter_PWM<'d6)&&(duty_cycle=='d4) ||
				(counter_PWM<'d8)&&(duty_cycle=='d5) ||
				(counter_PWM<'d11)&&(duty_cycle=='d6) ||
				(counter_PWM<'d14)&&(duty_cycle=='d7) ||
				(counter_PWM<'d18)&&(duty_cycle=='d8) ||
				(counter_PWM<'d24)&&(duty_cycle=='d9) ||
				(counter_PWM<'d29)&&(duty_cycle=='d10) ||
				(counter_PWM<'d35)&&(duty_cycle=='d11) ||
				(counter_PWM<'d42)&&(duty_cycle=='d12) ||
				(counter_PWM<'d51)&&(duty_cycle=='d13) ||
				(counter_PWM<'d61)&&(duty_cycle=='d14) ||
				(counter_PWM<'d74)&&(duty_cycle=='d15) ||
				(counter_PWM<'d89)&&(duty_cycle=='d16)) ? 1:0 ;		

generate
	// If PWM mod wire isn't installed
	if (!USE_PWM) begin
		//assign LCD_BKLT_PWM = 1;

	end

endgenerate
endmodule