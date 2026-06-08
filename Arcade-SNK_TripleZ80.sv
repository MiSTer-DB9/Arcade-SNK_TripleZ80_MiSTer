//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================
`default_nettype none

module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output 		  VGA_DISABLE,

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM (USE_FB=1 in qsf)
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + per-pin push-pull mask, USER_IO widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driven by wrapper; USER_OUT driven by joydb (USER_OUT_DRIVE) below
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

//assign VGA_SL = 0;
assign VGA_F1 = 0;
assign VGA_SCALER = status[14];
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;
assign VGA_DISABLE = 0;

//assign LED_DISK = 0;
//assign LED_POWER = 0;
assign BUTTONS = 0;

//////////////////////////////////////////////////////////////////

wire [1:0] ar = status[9:8];
wire orientation = ~status[10];
wire [2:0] scan_lines = status[6:4];
wire        direct_video;
wire forced_scandoubler;
wire [21:0] gamma_bus;

assign VIDEO_ARX = (!ar) ? (orientation  ? 8'd4 : 8'd3) : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? (orientation  ? 8'd3 : 8'd4) : 12'd0;


// Status Bit Map:
//             Upper                             Lower              
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X   XXX XXXX  XXXXXXX
`include "build_id.v" 
localparam CONF_STR = {
	"SNK_TripleZ80;;",
	"-;",
    "P1,Screen Settings;",
    "P1-;",
    "P1O[9:8],Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"P1O[10],Orientation,Horz.,Vert.;",
	"P1O[11],Rotate CW,Off,On;",
	"P1O[6:4],Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;",
	"P1-;",
	"-;",
	"P2,Other Settings;",
	"P2-;",
	"P2O[14],VGA Scaler,Off,On;",
	"P2O[15],Flip,Off,On;",
	"P2O[16],Side Layer,On,Off;",
	"P2O[17],Back Layer,On,Off;",
	"P2O[18],Front Layer,On,Off;",
	"P2-;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players, 1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"DIP;",
	"-;",
	"T[0],Reset;",
	"R[0],Reset and close OSD;",
	"J1,Fire,Missile,Armor,Start,Coin,Pause,Service;",
	"jn,A,B,C,Start,X,Y,Z;",
	"V,v",`BUILD_DATE 
};

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;
wire  [7:0] ioctl_index;
wire        ioctl_wait;
wire        rom_download = ioctl_download && (ioctl_index  == 0);

//Debug enable/disable Graphics layers
reg   [2:0] layer_ena_dbg = 3'b111;
always @(posedge clk_53p6) begin
	layer_ena_dbg[0] <= ~status[16]; //SIDE
	layer_ena_dbg[1] <= ~status[17]; //BACK1
	layer_ena_dbg[2] <= ~status[18]; //FRONT
end


//wire forced_scandoubler;

wire  [1:0] buttons;
wire [127:0] status;
wire [10:0] ps2_key;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: rename USB joystick wires
wire [15:0] joystick_0_USB, joystick_1_USB;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - DB controllers muted while OSD is open; remap joydb bits to SNK_TripleZ80 order
// Consumer button order (CONF_STR "J1,Fire,Missile,Armor,Start,Coin,Pause,Service"):
//   [3:0]=R/L/D/U  [4]=Fire  [5]=Missile  [6]=Armor  [7]=Start  [8]=Coin  [9]=Service  [10]=Pause
// joydb_1 source bits: [3:0]=R/L/D/U [4]=A [5]=B [6]=C [8]=Y [9]=Z [10]=Start [11]=Mode/R
//   Fire    <- joydb_1[4]  (A)
//   Missile <- joydb_1[5]  (B)
//   Armor   <- joydb_1[6]  (C)
//   Start   <- joydb_1[10] (Start)
//   Coin    <- joydb_1[11] (Mode/R-trigger)
//   Service <- joydb_1[9]  (Z,  spare face button)  -- best-effort
//   Pause   <- joydb_1[8]  (Y,  spare face button)  -- best-effort
// NOTE: this is an 8-way+3-fire (Alpha Mission / ASO / Arian Mission) board; it
// has no rotary control, so no rotate-left/right buttons exist to map.
wire [15:0] joystick_0 = joydb_1ena ? (OSD_STATUS ? 16'b0 : {5'b0, joydb_1[8], joydb_1[9], joydb_1[11], joydb_1[10], joydb_1[6], joydb_1[5], joydb_1[4], joydb_1[3:0]}) : joystick_0_USB;
wire [15:0] joystick_1 = joydb_2ena ? (OSD_STATUS ? 16'b0 : {5'b0, joydb_2[8], joydb_2[9], joydb_2[11], joydb_2[10], joydb_2[6], joydb_2[5], joydb_2[4], joydb_2[3:0]}) : joydb_1ena ? joystick_0_USB : joystick_1_USB;
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];
// SNAC cores: replace 1'b0 with the core's SNAC enable expression so SNAC
// preempts the joydb wrapper on shared USER_IO pins. Default 1'b0 is no-op.
wire         snac_active     = 1'b0;
// MT32-pi cores on primary USER_IO: replace 1'b0 with the core's MT32-active
// expression. Default 1'b0 (no MT32 on this core).
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire  [15:0] joy_raw_payload;

// [MiSTer-DB9 BEGIN] - DB9 programmable-remap matrix wires
// joydb_*_mapped = MiSTer-standard joystick words (consumed in Layer B);
// db9_remap_* = 0xFD selector stream driven by the hps_io instance.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_53p6),
	.HPS_BUS(HPS_BUS),
	.EXT_BUS(),
	.gamma_bus(),
	.forced_scandoubler(),
	.buttons(buttons),
	.status(status),
	.status_menumask(direct_video),
	.direct_video(direct_video),
   .forced_scandoubler(forced_scandoubler),
   .gamma_bus(gamma_bus),
	.ioctl_download(ioctl_download),
	.ioctl_upload(ioctl_upload),
	.ioctl_upload_req(ioctl_upload_req),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	.ioctl_din(ioctl_din),
	.ioctl_index(ioctl_index),
	.ioctl_wait(ioctl_wait),
	
	.ps2_key(ps2_key),
	.joystick_0(joystick_0_USB),
	.joystick_1(joystick_1_USB),
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw
	.joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
	// programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
	.db9_remap_cmd(db9_remap_cmd),
	.db9_remap_byte_cnt(db9_remap_byte_cnt),
	.db9_remap_din(db9_remap_din),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

// PAUSE SYSTEM
wire pause_cpu;

wire [23:0] rgb_out;

pause #(8,8,8,536) pause (
 .*,
 //.OSD_STATUS(1'b0), //pause only on user defined button
 .clk_sys(clk_53p6),
 .reset(reset),
 .user_button((m_pause1 | m_pause2)),
 .r(R8B),
 .g(G8B),
 .b(B8B),
 .pause_cpu(pause_cpu),
 .pause_request(),
 .options(~status[22:21])
);

// Video rotation 
wire rotate_ccw = ~status[11];
wire no_rotate = orientation | direct_video;
wire video_rotated;
wire flip = status[15];

screen_rotate screen_rotate (.*);

arcade_video #(288,24) arcade_video
(
        .*,

        .clk_video(clk_53p6),
        .ce_pix(ce_pix),

        .RGB_in(rgb_out),
	    //.RGB_in({R8B,G8B,B8B}),
        .HBlank(HBlank),
        .VBlank(VBlank),
        .HSync(HSync),
        .VSync(VSync),

        .fx(scan_lines)
);

///////////////////////   CLOCKS and POR  ///////////////////////////////

wire clk_sys;
wire clk_53p6;
pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_53p6)
);

wire reset = RESET | status[0] | buttons[1] | ioctl_download;
	
// <<< Start of Integration on Alpha Mission Core on MiSTer >>>
wire HBlank;
wire HSync;
wire VBlank;
wire VSync;
wire ce_pix;
wire [3:0] R,G,B;
wire [15:0] snd;
logic [15:0] PLAYER1, PLAYER2;

SNK_TripleZ80 snk_TZ80_ASO
(
	.RESETn(~reset),
	.VIDEO_RSTn(~reset),
	.pause_cpu(pause_cpu),
	//.pause_cpu(1'b0),
	.i_clk(clk_53p6), //53.6MHz
	.DSW({dsw2,dsw1}),
	.PLAYER1(PLAYER1),
	.PLAYER2(PLAYER2),
	.GAME(game), //default ASO (ASO,Alpha Mission, Arian Mission)
	//hps_io rom interface
	.ioctl_addr(ioctl_addr[24:0]),
	.ioctl_wr(ioctl_wr && rom_download),
	.ioctl_data(ioctl_dout),
	.layer_ena_dbg(layer_ena_dbg),
	//output
	.R(R),
	.G(G),
	.B(B),
	.HBLANK(HBlank),
	.VBLANK(VBlank),
	.HSYNC(HSync),
	.VSYNC(VSync),
	.CE_PIXEL(ce_pix),
	.snd(snd)
);

//color LUT for 4bit component to 8bit non-linear scale conversion (from LT Spice calculated values)
logic [7:0] R8B, G8B, B8B;
RGB4bit_LUT R_LUT( .COL_4BIT(R), .COL_8BIT(R8B));
RGB4bit_LUT G_LUT( .COL_4BIT(G), .COL_8BIT(G8B));
RGB4bit_LUT B_LUT( .COL_4BIT(B), .COL_8BIT(B8B));
// >>> End of Integration on Alpha Mission Core on MiSTer <<<

// assign CLK_VIDEO = clk_sys;
assign CLK_VIDEO = clk_53p6;

//Audio
assign AUDIO_S = 1'b1; //Signed audio samples
assign AUDIO_MIX = 2'b00; //no mix

//synchronize audio
reg [15:0] snd_r;
always @(posedge CLK_AUDIO) begin
	snd_r <= snd;
	AUDIO_L <= snd_r;
	AUDIO_R <= snd_r;
end


//////// Game inputs, the same controls are used for two player alternate gameplay ////////
//Dip Switches
// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_53p6) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end

//Added support for multigame core.
reg [7:0] game;
always @(posedge clk_53p6) begin
	if((ioctl_index == 1) && (ioctl_addr == 0)) begin
		game <= ioctl_dout;
	end
end

logic [7:0] dsw1, dsw2;
assign dsw1 = sw[0];
assign dsw2 = {sw[1][7:6], ~sw[1][5], sw[1][4:0]};
//Keyboard

//Joysticks
//Player 1
wire m_up1;
wire m_down1;
wire m_left1;
wire m_right1;
wire m_shot1;
wire m_missile1;
wire m_armor1;
wire m_service1;
wire m_start1;
wire m_coin1;
wire m_pause1; //active high

//Player 2
wire m_up2;
wire m_down2;
wire m_left2;
wire m_right2;
wire m_shot2;
wire m_missile2;
wire m_armor2;
wire m_service2;
wire m_start2;
wire m_coin2;
wire m_pause2; //active high

//custom_joy1:13 UP,12 DOWN,11 RIGHT,10 LEFT,9 H,8 G,7 F,6 E,5 D,4 C,3 B,2 A,1 START1,0 COIN
//db15:        //    11 L, 10 S, 9 F, 8 E, 7 D, 6 C, 5 B, 4 A, 3 U, 2 D, 1 L, 0 R
//    10 9876543210
//----LS FEDCBAUDLR

	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: DB15/DB9MD/Saturn now flow through
	// joystick_0/_1 via the joydb wrapper (remapped to this core's bit order at
	// the joystick_0/_1 mux above), so the upstream SNAC_dev/JOY_DB ternaries are
	// removed and these reads are plain joystick_0/_1 again.
	assign m_up1       = ~joystick_0[3];
	assign m_down1     = ~joystick_0[2];
	assign m_left1     = ~joystick_0[1];
	assign m_right1    = ~joystick_0[0];
	assign m_shot1     = ~joystick_0[4];
	assign m_missile1  = ~joystick_0[5];
	assign m_armor1    = ~joystick_0[6];
	assign m_start1    = ~joystick_0[7];
	assign m_coin1     = ~joystick_0[8];
	assign m_service1  = ~joystick_0[9];
	assign m_pause1    =  joystick_0[10];

	assign m_up2       = ~joystick_1[3];
	assign m_down2     = ~joystick_1[2];
	assign m_left2     = ~joystick_1[1];
	assign m_right2    = ~joystick_1[0];
	assign m_shot2     = ~joystick_1[4];
	assign m_missile2  = ~joystick_1[5];
	assign m_armor2    = ~joystick_1[6];
	assign m_start2    = ~joystick_1[7];
	assign m_coin2     = ~joystick_1[8];
	assign m_service2  = ~joystick_1[9];
	assign m_pause2    =  joystick_1[10];
	// [MiSTer-DB9 END]

assign PLAYER1 = {2'b11,m_up1,m_down1,m_right1,m_left1,m_service1,4'b1111, m_armor1,m_missile1,m_shot1,m_start1,m_coin1};
assign PLAYER2 = {2'b11,m_up2,m_down2,m_right2,m_left2,m_service2,4'b1111, m_armor1,m_missile1,m_shot1,m_start1,m_coin1};

endmodule
