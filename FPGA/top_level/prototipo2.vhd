library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity  prototipo2 is
generic(
		digits_display:integer :=6);
port (


----------WM8731 pins-----
AUD_BCLK: out std_logic;
AUD_XCK: out std_logic;
AUD_ADCLRCK:  out std_logic;
AUD_ADCDAT: in std_logic;
AUD_DACLRCK: out std_logic;
AUD_DACDAT: OUT std_logic;

---------FPGA pins-----

clock_50: in std_logic;
key: in std_logic_vector(3 downto 0);
ledr: out std_logic_vector(10 downto 0);
ledg: out std_logic_vector(7 downto 0);
sw: in std_logic_vector(9 downto 0);
display_7seg: out std_LOGIC_VECTOR(digits_display*7-1 DOWNTO 0);
FPGA_I2C_SCLK: out std_logic;
FPGA_I2C_SDAT: inout std_logic;


--------uart pins-----------

tx: out std_logic;
rx: in std_logic

);

end prototipo2;































architecture main of prototipo2 is

TYPE machine_send IS(idle, send_number,send_nl);
SIGNAL state_send :  machine_send;
signal state_send_dft : machine_send;


type machine_capture is(idle,capture,end_capture);
signal state_capture: machine_capture;	



type machine_configure is(idle,data1,data1_off,data2,data2_off,data3,data3_off,data4,data4_off,data5,data5_off,
				data6,data6_off,data7,data7_off,reset,reset_off);
signal state_configure: machine_configure;							--needed states


type machine_sonometer is(idle,st1,st2,st3,st4,st5,st6,st7,st8,st9,st10,st11,st12,st13,st14,st15,st16,
			st17,st18,st19,st20,st21,st22,reset);
signal state_sonometer : machine_sonometer;


type shift_register is array (14 downto 0) of std_logic_vector(31 downto 0);
signal d: shift_register;
signal df: shift_register;
signal dft: shift_register;






signal prescaler_2seg: integer range 0 to 50000000:=0;
signal prescaler_2seg_dft: integer;
signal sample_count: integer range 0 to 200000:=0;
signal digit_to_send: integer range 0 to 10:=5;
signal digit_to_send_dft:integer range 0 to 20:=10;
signal to_show: integer:=0;
signal time_cont: integer range 0 to 50000000:=0;
signal suma: integer;
signal cont_suma: integer;
signal promedio: integer;



signal aud_mono: std_logic_vector(15 downto 0):=(others=>'0');
signal WM_i2c_busy: std_logic;
signal WM_i2c_done: std_logic;
signal WM_i2c_send_flag: std_logic;
signal WM_i2c_data: std_logic_vector(15 downto 0);
signal AD_CLKR: std_logic:='0';
signal NEW_SAMPLE: std_logic:='0';
signal NEW_SAMPLE_old: std_logic;

signal fifod_rd_req: std_logic:='0';
signal fifod_clear: std_logic:='0';
signal fifod_wr_req: std_logic:='0';
signal fifod_empty_flag: std_logic:='0';
signal fifod_full_flag: std_logic:='0';
signal fifOd_buffer_out: std_logic_vector(15 downto 0);
signal fifod_rd_req_old: std_logic; 
signal fifod_used_words: std_logic_vector(15 downto 0);

signal fifodft_rd_req: std_logic:='0';
signal fifodft_clear: std_logic:='0';
signal fifodft_wr_req: std_logic:='0';
signal fifodft_empty_flag: std_logic:='0';
signal fifodft_full_flag: std_logic:='0';
signal fifOdft_data: std_logic_vector(31 downto 0);
signal fifOdft_buffer_out: std_logic_vector(31 downto 0);
signal fifodft_rd_req_old: std_logic; 
signal fifodft_used_words: std_logic_vector(15 downto 0);


signal aud_capture_flag: std_logic:='0';
signal aud_capture_flag_old: std_logic;

signal uart_wr_buffer: std_logic_vector(7 downto 0);
signal uart_send: std_logic;
signal uart_tx_full_flag: std_logic;
signal tx1:std_logic;


signal uart_wr_buffer_dft: std_logic_vector(7 downto 0);
signal uart_send_dft: std_logic;
signal uart_tx_full_flag_dft: std_logic;
signal tx2:std_logic;


signal bcd_start: std_logic;
signal bcd_flag: std_logic;
signal bcd_buffer: std_logic_vector(19 downto 0);

signal bcd_in_buffer_dft: std_logic_vector(31 downto 0);
signal bcd_start_dft: std_logic;
signal bcd_flag_dft: std_logic;
signal bcd_out_buffer_dft: std_logic_vector(39 downto 0);
	
signal int_to_float_done:std_logic;
signal int_to_float_start: std_logic;
signal int_to_float_result: std_logic_vector(31 downto 0);	
signal int_to_float_data_a: std_logic_vector(31 downto 0);
signal int_to_float_data_b: std_logic_vector(31 downto 0);
	
signal float_to_int_done:std_logic;
signal float_to_int_start: std_logic;
signal float_to_int_result: std_logic_vector(31 downto 0);	
signal float_to_int_data_a: std_logic_vector(31 downto 0);
signal float_to_int_data_b: std_logic_vector(31 downto 0);
	
signal mult_d_start:std_logic;
signal mult_d_result: shift_register;
signal mult_d_done: std_logic_vector(6 downto 0);
signal mult_d_done_sum:std_logic;
signal coef_num_A: shift_register;
signal coef_num_C: shift_register;
signal coef_num_F: shift_register;
signal coef_num_S: shift_register;
signal coef_num: shift_register;

signal adder_f_done:std_logic;
signal adder_f_start: std_logic;
signal adder_f_result: std_logic_vector(31 downto 0);	
signal adder_f_data_a: std_logic_vector(31 downto 0);
signal adder_f_data_b: std_logic_vector(31 downto 0);
signal k: integer:=0;	
	
signal mult_df_start:std_logic;
signal mult_df_result: shift_register;
signal mult_df_done: std_logic_vector(6 downto 0);
signal mult_df_done_sum:std_logic;
signal coef_den_A: shift_register;	
signal coef_den_C: shift_register;
signal coef_den_F: shift_register;	
signal coef_den_S: shift_register;
signal coef_den: shift_register;		
	
signal square_done:std_logic;
signal square_start: std_logic;
signal square_result: std_logic_vector(31 downto 0);	
signal square_data_a: std_logic_vector(31 downto 0);
signal square_data_b: std_logic_vector(31 downto 0);

signal sqrt_done:std_logic;
signal sqrt_start: std_logic;
signal sqrt_result: std_logic_vector(31 downto 0);	

signal log_result: std_logic_vector(31 downto 0);
signal log_counter: integer;

signal sum_data_a:std_logic_vector(31 downto 0);
signal sum_data_b: std_logic_vector(31 downto 0);
signal sum_start:std_logic;
signal sum_done:std_logic;
signal sum_result: std_logic_vector(31 downto 0);

signal prom_data_a:std_logic_vector(31 downto 0);
signal prom_data_b: std_logic_vector(31 downto 0);
signal prom_start:std_logic;
signal prom_done:std_logic;
signal prom_result: std_logic_vector(31 downto 0);


signal log_20_start:std_logic;
signal log_20_done:std_logic;
signal log_20_result: std_logic_vector(31 downto 0);


signal key_old:std_logic_vector(3 downto 0);
signal clock_12pll:std_logic;
signal sw_old:std_logic_vector(9 downto 0);
signal k_amp : integer;
signal data_in:integer;
signal result:integer;
signal result2:integer;
signal calibracion:integer;













	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
 component floating_point is
		port (
			clk_clk       : in  std_logic                     := 'X';             -- clk
			reset_reset_n : in  std_logic                     := 'X';             -- reset_n
			s1_dataa      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- dataa
			s1_datab      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datab
			s1_n          : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- n
			s1_result     : out std_logic_vector(31 downto 0);                    -- result
			s2_clk        : in  std_logic                     := 'X';             -- clk
			s2_clk_en     : in  std_logic                     := 'X';             -- clk_en
			s2_dataa      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- dataa
			s2_datab      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datab
			s2_n          : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- n
			s2_reset      : in  std_logic                     := 'X';             -- reset
			s2_reset_req  : in  std_logic                     := 'X';             -- reset_req
			s2_start      : in  std_logic                     := 'X';             -- start
			s2_done       : out std_logic;                                        -- done
			s2_result     : out std_logic_vector(31 downto 0)                     -- result
		);
	end component floating_point;



component pll_cyclone4e is
	port (
		clk_clk       : in  std_logic := '0'; --      clk.clk
		clock_12_clk  : out std_logic;        -- clock_12.clk
		reset_reset_n : in  std_logic := '0'  --    reset.reset_n
	);
end component pll_cyclone4e;


		  
		  

 component aud_gen is
 port (
	aud_clock_12: in std_logic;
	aud_bk: out std_logic;
	aud_adlr: out std_logic;
	aud_addat: in std_logic;
	aud_data_out: out std_logic_vector(15 downto 0);
	new_sample_flag: out std_logic
 ); 
 end component aud_gen;





 component i2c is
 port(
	i2c_busy: out std_logic;
	i2c_scl: out std_logic;
	i2c_send_flag: in std_logic;
	i2c_sda: inout std_logic;
	i2c_addr: in std_logic_vector(7 downto 0);
	i2c_done: out std_logic;
	i2c_data: in std_logic_vector(15 downto 0);
	i2c_clock_50: in std_logic
 );
 end component i2c;
 
 
 
 
 component seven_segments IS
	GENERIC(
		bits			:	INTEGER := 16;			--allowable size of the input numbers in bits
		digits		:	INTEGER := 6;			--number of seven segment displays
		ss_polarity	:	STD_LOGIC := '0');	--7-seg display connection polarity, '0' = common anode, '1' = common cathode
	PORT(
		clk				:	IN		STD_LOGIC;											--system clock
		reset_n			:	IN		STD_LOGIC;											--active low asynchronus reset		
		number			:	IN		INTEGER;												--number to display on the 7 segment displays
		displays_7seg	:	OUT	STD_LOGIC_VECTOR(digits*7-1 DOWNTO 0));	--outputs to 7 segment displays
END component seven_segments;
 
 

	
	
 
 component FIFO65k15 IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component FIFO65k15;


component fifo65k32 IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		rdreq		: IN STD_LOGIC ;
		sclr		: IN STD_LOGIC ;
		wrreq		: IN STD_LOGIC ;
		empty		: OUT STD_LOGIC ;
		full		: OUT STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		usedw		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
	);
END component;
 
 
 
component uart is
   generic(
      -- Default settings:
      -- 19,200 baud, 8 data bits, 1 stop bits, 2^5 FIFO
      DBIT: integer:=8;     -- # data bits
      SB_TICK: integer:=16; -- # ticks for stop bits, 16/24/32 for 1/1.5/2 stop bits
      DVSR: integer:= 163;  -- baud rate divisor; DVSR = 50M/(16*baud rate)
            -- Note: read page 174 in P.P. Chu's textbook; this is so, because
            -- my De2-115 board has an off chip oscillator that gives me 50 MHz;
      DVSR_BIT: integer:=9; -- # bits of DVSR
      FIFO_W: integer:=5    -- # addr bits of FIFO
                            -- # words in FIFO=2^FIFO_W
   ); 
   port(
      clk: in std_logic; -- 50 MHz in the case of DE2-115 board;
      reset: in std_logic;
      rd_uart, wr_uart: in std_logic;
      rx: in std_logic;
      w_data: in std_logic_vector(7 downto 0);
      tx_full, rx_empty: out std_logic;
      r_data: out std_logic_vector(7 downto 0);
      tx: out std_logic
   );
end component uart;
 
 
 
component binary_to_bcd IS
	GENERIC(
		bits		:	INTEGER := 10;		--size of the binary input numbers in bits
		digits	:	INTEGER := 3);		--number of BCD digits to convert to
	PORT(
		clk		:	IN		STD_LOGIC;											--system clock
		reset_n	:	IN		STD_LOGIC;											--active low asynchronus reset
		ena		:	IN		STD_LOGIC;											--latches in new binary number and starts conversion
		binary	:	IN		STD_LOGIC_VECTOR(bits-1 DOWNTO 0);			--binary number to convert
		busy		:	OUT	STD_LOGIC;											--indicates conversion in progress
		bcd		:	OUT	STD_LOGIC_VECTOR(digits*4-1 DOWNTO 0));	--resulting BCD number
END component binary_to_bcd;
 
 
component prueba1 IS
	PORT
	(
		clock		: IN STD_LOGIC ;
		data		: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		result		: OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
	);
END component prueba1;






 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

begin


 pll : component pll_cyclone4e
        port map (
            clk_clk       => clock_50,                                           -- clk.clk
            reset_reset_n => '1',                                                -- reset.reset_n
            clock_12_clk  => clock_12pll 												   -- clock_12.clk
				);




sound: component aud_gen
		port map(
		aud_clock_12=>clock_12pll,
		aud_bk=>AUD_BCLK,
		aud_adlr=>AD_CLKR,
		aud_addat=>AUD_ADCDAT,	
		aud_data_out=>aud_mono,
		new_sample_flag=>NEW_SAMPLE

		);

WM8731: component i2c 
		port map(
			i2c_busy=>WM_i2c_busy,
			i2c_scl=>FPGA_I2C_SCLK,
			i2c_send_flag=>WM_i2c_send_flag,
			i2c_sda=>FPGA_I2C_SDAT,
			i2c_addr=>"00110100",
			i2c_done=>WM_i2c_done,
			i2c_data=>WM_i2c_data,
			i2c_clock_50=>clock_50	
		);
		
bin27seg: component seven_segments
		port map(
				clk => clock_50,
				reset_n => '1',
				--number => to_integer(unsigned(fifO65k16_buffer_out)),
				number => to_show,
				displays_7seg => display_7seg
		);

		
		


		
fifod : component FIFO65k15
		port map(
				clock=> clock_50,
				data=> aud_mono,
				rdreq=> fifod_rd_req,
				sclr=> fifod_clear,
				wrreq=> fifod_wr_req,
				empty=> fifod_empty_flag,
				full=> fifod_full_flag,
				q=> fifOd_buffer_out,
				usedw=>fifod_used_words
		);
		
fifodft : component FIFO65k32
		port map(
				clock=> clock_50,
				data=> fifodft_data,
				rdreq=> fifodft_rd_req,
				sclr=> fifodft_clear,
				wrreq=> fifodft_wr_req,
				empty=> fifodft_empty_flag,
				full=> fifodft_full_flag,
				q=> fifOdft_buffer_out,
				usedw=>fifodft_used_words
		);
		
	
	

uart_instance: component uart
			generic map(
--					DBIT,
--					SB_TICK,
					DVSR=>27		--115200
--					DVSR_BIT,
--					FIFO_W
			)
			port map(
					clk=>clock_50,
					reset=>sw(7),
					rd_uart=>'0',
					wr_uart=>uart_send,
					rx=>'0',
					tx=>tx1,
					w_data=>uart_wr_buffer,
					r_data=>open,
					tx_full=>uart_tx_full_flag,
					rx_empty=>open
			);
			
uart_instance_dft: component uart
			generic map(
--					DBIT,
--					SB_TICK,
					DVSR=>27		--115200
--					DVSR_BIT,
--					FIFO_W
			)
			port map(
					clk=>clock_50,
					reset=>sw(7),
					rd_uart=>'0',
					wr_uart=>uart_send_dft,
					rx=>'0',
					tx=>tx2,
					w_data=>uart_wr_buffer_dft,
					r_data=>open,
					tx_full=>uart_tx_full_flag_dft,
					rx_empty=>open
			);
			
binary_to_bcd_instance: component binary_to_bcd	
				generic map(
						bits=>16,
						digits=>5
				)
				port map(
						clk=>clock_50,
						reset_n=>not sw(7),
						ena=>bcd_start,
						binary=>fifOd_buffer_out,
						busy=>bcd_flag,
						bcd=>bcd_buffer
				);
				
binary_to_bcd_dft: component binary_to_bcd	
				generic map(
						bits=>32,
						digits=>10
				)
				port map(
						clk=>clock_50,
						reset_n=>not sw(7),
						ena=>bcd_start_dft,
						binary=>bcd_in_buffer_dft,
						busy=>bcd_flag_dft,
						bcd=>bcd_out_buffer_dft
				);
		

int_to_float : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => int_to_float_data_a,      --      .dataa
			s2_datab      => int_to_float_data_b,      --      .datab
			s2_n          => "010",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => int_to_float_start,      --      .start
			s2_done       => int_to_float_done,       --      .done
			s2_result     => int_to_float_result      --      .result
		);
		
		
float_to_int : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => float_to_int_data_a,      --      .dataa
			s2_datab      => float_to_int_data_b,      --      .datab
			s2_n          => "000",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => float_to_int_start,      --      .start
			s2_done       => float_to_int_done,       --      .done
			s2_result     => float_to_int_result      --      .result
		);
		
		
mult_d : for i in 0 to 6 generate 
	multi_d: floating_point port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => d(i),      --      .dataa
			s2_datab      => coef_num(i),      --      .datab
			s2_n          => "100",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => mult_d_start,      --      .start
			s2_done       => mult_d_done(i),       --      .done
			s2_result     => mult_d_result(i)      --      .result
		);	end generate mult_d;
	
adder_f : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => adder_f_data_a,      --      .dataa
			s2_datab      => adder_f_data_b,      --      .datab
			s2_n          => "101",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => adder_f_start,      --      .start
			s2_done       => adder_f_done,       --      .done
			s2_result     => adder_f_result      --      .result
		);
	
	
mult_df : for j in 1 to 6 generate 
	multi_df: floating_point port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => dft(j),      --      .dataa
			s2_datab      => coef_den(j),      --      .datab
			s2_n          => "100",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => mult_df_start,      --      .start
			s2_done       => mult_df_done(j),       --      .done
			s2_result     => mult_df_result(j)      --      .result
		);	end generate mult_df;

square : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => int_to_float_result,      --      .dataa
			s2_datab      => int_to_float_result,      --      .datab
			s2_n          => "100",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => square_start,      --      .start
			s2_done       => square_done,       --      .done
			s2_result     => square_result      --      .result
		);

sqrt : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => prom_result,      --      .dataa
			s2_datab      => (others=>'0'),      --      .datab
			s2_n          => "011",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => sqrt_start,      --      .start
			s2_done       => sqrt_done,       --      .done
			s2_result     => sqrt_result      --      .result
		);

log : prueba1 PORT MAP (
		clock	 => clock_50,
		data	 => sqrt_result,
		result	 => log_result
	);

	
sum : component floating_point
		port map (
--			clk_clk       => clock_50,       --   clk.clk
--			reset_reset_n => sw(7), -- reset.reset_n
--			s1_dataa      => s1_dataa,      --    s1.dataa
--			s1_datab      => s1_datab,      --      .datab
--			s1_n          => s1_n,          --      .n
--			s1_result     => s1_result,     --      .result
			
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => sum_data_a,      --      .dataa
			s2_datab      => sum_data_b,      --      .datab
			s2_n          => "101",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => sum_start,      --      .start
			s2_done       => sum_done,       --      .done
			s2_result     => sum_result      --      .result
		);

prom : component floating_point
		port map (
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => prom_data_a,      --      .dataa
			s2_datab      => prom_data_b,      --      .datab
			s2_n          => "111",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => prom_start,      --      .start
			s2_done       => prom_done,       --      .done
			s2_result     => prom_result      --      .result
		);

	
log_20 : component floating_point
		port map (
			s2_clk        => clock_50,        --    s2.clk
			s2_clk_en     => '1',     --      .clk_en
			s2_dataa      => log_result,      --      .dataa
			s2_datab      => "01000010101011011011011111000001",      --      .datab x200, 20 por el log y 10 para decimales
			s2_n          => "100",          --      .n
			s2_reset      => sw(7),      --      .reset
			s2_reset_req  => '0',  --      .reset_req
			s2_start      => log_20_start,      --      .start
			s2_done       => log_20_done,       --      .done
			s2_result     => log_20_result      --      .result
		);

	
AUD_XCK<=clock_12pll;
AUD_ADCLRCK<=AD_CLKR;
	

ledg(6)<=fifod_empty_flag;
ledg(5)<=fifodft_empty_flag;

tx<=tx1 and tx2;	--trabajan con logica negativa

bcd_in_buffer_dft<=fifodft_buffer_out;


--to_show<=to_integer(unsigned(float_to_int_result));


int_to_float_data_b<=(others=>'0');


float_to_int_data_b<=(others=>'0');


coef_num_A(0)<="00111100110000000001110010010000";-- 
coef_num_A(1)<="10111101010000000001110010010000";-- 
coef_num_A(2)<="10111100110000000001110010010000";-- 
coef_num_A(3)<="00111101110000000001110010010000";-- 
coef_num_A(4)<="10111100110000000001110010010000";-- 
coef_num_A(5)<="10111101010000000001110010010000";-- 
coef_num_A(6)<="00111100110000000001110010010000";-- 

coef_den_A(0)<="10111111100000000000000000000000";-- 	
coef_den_A(1)<="01000000100000111001111000011011";-- 
coef_den_A(2)<="11000000110100011011001101111000";-- 
coef_den_A(3)<="01000000100111111011010110011010";-- 
coef_den_A(4)<="10111111111001001001010011101110";-- 
coef_den_A(5)<="00111110011111000001111010111101";-- 
coef_den_A(6)<="00111100001101111110110101000010";-- 

coef_num_C(0)<="00111110010010010011000110000110";-- 
coef_num_C(1)<="10100110100000000000000000000000";-- 
coef_num_C(2)<="10111110110010010011000110000110";-- 
coef_num_C(3)<="00100110000100000000000000000000";-- 
coef_num_C(4)<="00111110010010010011000110000110";-- 
coef_num_C(5)<="00000000000000000000000000000000";-- 
coef_num_C(6)<="00000000000000000000000000000000";-- 

coef_den_C(0)<="10111111100000000000000000000000";-- 	
coef_den_C(1)<="01000000000011100000011100110110";-- 
coef_den_C(2)<="10111111101110100100001100011000";-- 
coef_den_C(3)<="00111110011111100111101101011010";-- 
coef_den_C(4)<="00111100010011010111011111011010";-- 
coef_den_C(5)<="00000000000000000000000000000000";-- 
coef_den_C(6)<="00000000000000000000000000000000";-- 

coef_den_F(0)<="10111111100000000000000000000000";-- 
coef_den_F(1)<="00111111011111111111010100010100";-- 
coef_num_F(0)<="00111000101011101011111110000100";-- 
coef_num_F(1)<="00111000101011101011111110000100";-- 

coef_den_S(0)<="10111111100000000000000000000000";-- 
coef_den_S(1)<="00111111011111111111111010100010";-- 
coef_num_S(0)<="00110111001011101100001011000111";-- 
coef_num_S(1)<="00111101110101010101010011000100";-- 




mult_d_done_sum<= mult_d_done(0) and mult_d_done(1) and mult_d_done(2) and mult_d_done(3) and 
			mult_d_done(4) and mult_d_done(5) and mult_d_done(6);

mult_df_done_sum<= mult_df_done(1) and mult_df_done(2) and mult_df_done(3) and 
		   mult_df_done(4) and mult_df_done(5) and mult_df_done(6);
			
		
		
ledr(8)<=adder_f_done;
ledr(6)<=mult_df_done(6);
ledr(4)<=mult_df_done_sum;			
						

			
with sw(3) select
	coef_den(0)<= 	coef_den_S(0) when '1',
			coef_den_F(0) when others;
		
		
with sw(3) select
	coef_den(1)<= 	coef_den_S(1) when '1',
			coef_den_F(1) when others;			

			
with sw(3) select
	coef_num(0)<= 	coef_num_S(0) when '1',
			coef_num_F(0) when others;

			
with sw(3) select
	coef_num(1)<= 	coef_num_S(1) when '1',
			coef_num_F(1) when others;

			
			

			
	


	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	



	
	
	
	

process (clock_50)
begin
	if(sw(7)='1')then
		k_amp<=10;
	else
		if(rising_edge(clock_50))then
			if(sw(4)='1')then
				--to_show<=k_amp;
				to_show<=calibracion;
				if(key(3)='1' and key_old(3)='0')then
					k_amp<=k_amp*10;
				else
					if(key(2)='1' and key_old(2)='0')then
						k_amp<=k_amp/10;
					end if;
				end if;
			else
				--to_show<=data_in;
				--to_show<=to_integer(unsigned(float_to_int_result));
				to_show<=result2;
			end if;
		end if;
	end if;
end process;
		
		

process (clock_50)
begin
	--if(sw(7)='1' and sw_old(7)='0')then			--filtro A/C funcionando
	if(KEY(1)='0' and key_old(1)='1')then 			-- problemas con el redondeo de los float
		state_sonometer<=reset;
	else
		if(sw(5)='1' and sw_old(5)='0')then
			calibracion<=0;
		else
			if(rising_edge(clock_50))then
				int_to_float_start<='0';
				float_to_int_start<='0';
				mult_d_start<='0';
				adder_f_start<='0';
				mult_df_start<='0';
				ledr(5)<='0';
				sum_start<='0';
				prom_start<='0';
				square_start<='0';
				sqrt_start<='0';
				log_20_start<='0';
				case state_sonometer is
				when idle=>
					if(NEW_SAMPLE='1' and NEW_SAMPLE_old='0')then
						state_sonometer<=st1;
					end if;
					
				when st1=>
					data_in<=to_integer(signed(aud_mono));
					state_sonometer<=st5;
					
				when st5=>
					--data_in<=data_in*k_amp;
					state_sonometer<=st16;
					
				when st16=>				
	--				if(aud_mono(15)='1')then
	--				if(data_in<0)then
	--					int_to_float_data_a(31 downto 16)<=(others=>'1');
	--				else
	--					int_to_float_data_a(31 downto 16)<=(others=>'0');
	--				end if;
	--				int_to_float_data_a(15 downto 0)<=
	--					std_logic_vector(to_signed(data_in,16));
					int_to_float_data_a<=std_logic_vector(to_signed(data_in,32));
					int_to_float_start<='1';
					state_sonometer<=st2;
					
				when st2=>
					if(int_to_float_done='1')then
						square_start<='1';
						state_sonometer<=st3;
					end if;
					
				when st3=>
					if(square_done='1')then
						d(1)<=d(0);
						d(0)<=square_result;
						dft(1)<=dft(0);
						state_sonometer<=st4;
					end if;
				when st4=>
					mult_d_start<='1';
					mult_df_start<='1';
					state_sonometer<=st6;
				when st6=>
					if(mult_d_done_sum='1')then					
						state_sonometer<=st7;
					end if;
					
				when st7=>
					--k<=1;
					adder_f_data_a<=(others=>'0');
					adder_f_data_b<=mult_d_result(0);
					adder_f_start<='1';
					state_sonometer<=st8;
					
				when st8=>
					if(adder_f_done='1')then
						adder_f_data_a<=adder_f_result;
						adder_f_data_b<=mult_d_result(1);
						adder_f_start<='1';
						--k<=k+1;
						state_sonometer<=st9;
					end if;
					
				when st9=>
					if(adder_f_done='1')then
						adder_f_data_a<=adder_f_result;
						adder_f_data_b<=mult_df_result(1);
						adder_f_start<='1';
						state_sonometer<=st10;
					end if;
				when st10 =>
					if(adder_f_done='1')then
						dft(0)<=adder_f_result;
						state_sonometer<=st17;
					end if;
					
				when st17=>
					if(cont_suma<1000)then
						sum_data_a<=sum_result;
						sum_data_b<=dft(0);
						sum_start<='1';
						cont_suma<=cont_suma+1;
						state_sonometer<=idle;
					else
						prom_data_a<=sum_result;
						prom_data_b<=
							"01000100011110100000000000000000";	--1000
						--	"01000110001110111000000000000000";	--12000
						prom_start<='1';
						cont_suma<=1;
						state_sonometer<=st18;
					end if;
					
				when st18=>
					if(prom_done='1')then
						sum_data_a<=(others=>'0');
						sum_data_b<=dft(0);
						sum_start<='1';
						state_sonometer<=st11;
					end if;
					
				when st11=>
					if(sum_done='1')then
						sqrt_start<='1';
						state_sonometer<=st12;
					end if;
					
				when st12=>
					if(sqrt_done='1')then
						log_counter<=25;
						state_sonometer<=st13;					
					end if;	
					
				when st13=>
					if(log_counter=0)then
						log_20_start<='1';
						state_sonometer<=st19;
					else
						log_counter<=log_counter-1;
					end if;
					
				when st19=>
					if(log_20_done='1')then
						state_sonometer<=st14;
					end if;
					
				when st14=>
					float_to_int_data_a<=log_20_result;--dft(0);
					float_to_int_start<='1';
					state_sonometer<=st15;
					
				when st15=>
					if(float_to_int_done='1')then
						result<=to_integer(unsigned(float_to_int_result));
						state_sonometer<=st20;
					end if;
				when st20=>
					if(sw(8)='1')then
						calibracion<=result-800;
					end if;
					result2<=result-calibracion;
					state_sonometer<=st21;
				
				when st21=>		
					if(result2<1)then
						result2<=1;
					end if;
					state_sonometer<=st22;
					
				when st22=>
					--fifodft_data<=float_to_int_result;--////////////////////////
					fifodft_data<=std_logic_vector(to_unsigned(result2,32));
					state_sonometer<=idle;	
					
				
				when reset => 
					d<=(others=>"00000000000000000000000000000000");
					df<=(others=>"00000000000000000000000000000000");
					dft<=(others=>"00000000000000000000000000000000");
					sum_data_a<=(others=>'0');
					sum_data_b<=(others=>'0');
					sum_start<='1';
					cont_suma<=0;
					--
					state_sonometer<=idle;
					
				when others=> state_sonometer<=reset;
				end case;
			end if;
		end if;
	end if;
end process;
			
			
			
process (clock_50)		--registro de teclas 
begin
	if(rising_edge(clock_50))then
		key_old<=KEY;
		NEW_SAMPLE_old<=NEW_SAMPLE;
		sw_old<=sw;
	end if;
end process;





process (clock_50)		--proceso de captura
begin
	if(sw(7)='1')then
		state_capture<=idle;
	else
		if(rising_edge(clock_50))then
			fifod_clear<='0';
			fifod_wr_req<='0';
			fifodft_clear<='0';
			fifodft_wr_req<='0';
			case state_capture is
			when idle =>
				if(KEY(1)='0' and key_old(1)='1')then 
					sample_count<=0;
					fifod_clear<='1';
					fifodft_clear<='1';
					state_capture<=capture;
					aud_capture_flag<='1';
					ledg(7)<='1';
				else
					ledg(7)<='0';
				end if;
			when capture =>
				if(NEW_SAMPLE='1' and NEW_SAMPLE_old='0')then
					--if(dft(0)<0)then
						--fifodft_data<=std_logic_vector(to_signed(dft(0)+65536,32));
					--else
						--fifodft_data<=int_to_float_data_a;
						--fifodft_data<=float_to_int_result;
					--end if;
					fifodft_wr_req<='1';
					fifod_wr_req<='1';
					sample_count<=sample_count+1;
					
				else
					if(sample_count>=12000)then
						state_capture<=end_capture;
					end if;
				end if;
			when end_capture =>
				state_capture<=idle;
				aud_capture_flag<='0';
			when others => state_capture<=idle;
			end case;
		end if;
	end if;
end process;






process(clock_50)		--proceso de muestra
begin
	if(rising_edge(clock_50))then
		if(prescaler_2seg<500000)then
			prescaler_2seg<=prescaler_2seg+1;
			fifod_rd_req<='0';
			bcd_start<='0';
		else
			prescaler_2seg<=0;
			if(sw(0)='1' and fifod_empty_flag='0')then
				--serial_send_flag<='1';
				fifod_rd_req<='1';
				bcd_start<='1';
			end if;
		end if;
	end if;
end process;
			

		


process	(clock_50)		--envio por uart
begin
	if(sw(7)='1')then
		state_send<=idle;
	else
		if(rising_edge(clock_50))then
			case state_send is
			when idle=>
				uart_send<='0';
				if(fifod_rd_req='1' and fifod_rd_req_old='0')then
					state_send<=send_number;
					digit_to_send<=5;
				end if;
			when send_number=>
				if(uart_send='1')then
					uart_send<='0';
					if(digit_to_send=0)then
						state_send<=send_nl;
					end if;
				else
					if(bcd_flag='0')then
						uart_wr_buffer(7 downto 4)<="0011";
						uart_wr_buffer(3 downto 0)<=bcd_buffer((digit_to_send*4-1) 
										downto ((digit_to_send-1)*4));
						uart_send<='1';
						digit_to_send<=digit_to_send-1;
					end if;
				end if;
			when send_nl=>
				uart_wr_buffer<="00001010";
				uart_send<='1';
				state_send<=idle;
			when others=>
				state_send<=idle;
				uart_send<='0';
			end case;
			fifod_rd_req_old<=fifod_rd_req;
		end if;
	end if;
end process;




process(clock_50)		--proceso de muestra dft
begin
	if(rising_edge(clock_50))then
		if(prescaler_2seg_dft<500000)then
			prescaler_2seg_dft<=prescaler_2seg_dft+1;
			fifodft_rd_req<='0';
			bcd_start_dft<='0';
		else
			prescaler_2seg_dft<=0;
			if(sw(1)='1' and fifodft_empty_flag='0')then
				--serial_send_flag<='1';
				fifodft_rd_req<='1';
				bcd_start_dft<='1';
			end if;
		end if;
	end if;
end process;



process	(clock_50)		--envio por uart dft
begin
	if(sw(7)='1')then
		state_send_dft<=idle;
	else
		if(rising_edge(clock_50))then
			case state_send_dft is
			when idle=>
				uart_send_dft<='0';
				if(fifodft_rd_req='1' and fifodft_rd_req_old='0')then
					state_send_dft<=send_number;
					digit_to_send_dft<=10;
				end if;
			when send_number=>
				if(uart_send_dft='1')then
					uart_send_dft<='0';
					if(digit_to_send_dft=0)then
						state_send_dft<=send_nl;
					end if;
				else
					if(bcd_flag_dft='0')then
						uart_wr_buffer_dft(7 downto 4)<="0011";
						uart_wr_buffer_dft(3 downto 0)<=bcd_out_buffer_dft((digit_to_send_dft*4-1) downto ((digit_to_send_dft-1)*4));
						uart_send_dft<='1';
						digit_to_send_dft<=digit_to_send_dft-1;
					end if;
				end if;
			when send_nl=>
				uart_wr_buffer_dft<="00001010";
				uart_send_dft<='1';
				state_send_dft<=idle;
			when others=>
				state_send_dft<=idle;
				uart_send_dft<='0';
			end case;
			fifodft_rd_req_old<=fifodft_rd_req;
		end if;
	end if;
end process;




















process (clock_50)			--proceso de configuracion wm
begin

	if(sw(7)='1' and sw_old(7)='0')then
		state_configure<=reset;
		--ledg(0)<='0';
	else
		if (rising_edge(clock_50)) then
			WM_i2c_send_flag<='0';
			case state_configure is
			when idle =>
				if(key(0)='0' and key_old(0)='1' and WM_i2c_busy='0')then
					state_configure<=data1;
					ledg(0)<='1';
				else
						ledg(0)<='0';
				end if;
			when data1 =>
				WM_i2c_data(15 downto 9)<="0000111";
				WM_i2c_data(8 downto 0)<="000000011";	
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data1_off;
				end if;
			when data1_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data2;
				end if;
			when data2 =>
				WM_i2c_data(15 downto 9)<="0000000";
				WM_i2c_data(8 downto 0)<="100011111";
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data2_off;
				end if;
			when data2_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data3;
				end if;
			when data3 =>
				WM_i2c_data(15 downto 9)<="0000110";
				WM_i2c_data(8 downto 0)<="000001010";	
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data3_off;
				end if;
			when data3_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data4;
				end if;
			when data4 =>
				WM_i2c_data(15 downto 9)<="0001000";
				WM_i2c_data(8 downto 0)<="000000001";
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data4_off;
				end if;
			when data4_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data5;
				end if;
			when data5 =>
				WM_i2c_data(15 downto 9)<="0001001";
				WM_i2c_data(8 downto 0)<="111111111";	
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data5_off;
				end if;
			when data5_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data6;
				end if;
			when data6 =>
				WM_i2c_data(15 downto 9)<="0000100";
				WM_i2c_data(8 downto 0)<="000000010";
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data6_off;
				end if;
			when data6_off=>
				if(WM_i2c_busy='0')then
					state_configure<=data7;
				end if;
			when data7 =>
				WM_i2c_data(15 downto 9)<="0000101";
				WM_i2c_data(8 downto 0)<="000001000";	
				WM_i2c_send_flag<='1';
				if(WM_i2c_busy='1')then
					state_configure<=data7_off;
				end if;
			when data7_off=>
				if(WM_i2c_busy='0')then
					state_configure<=idle;
					ledg(0)<='0';
				end if;
			when reset =>
				WM_i2c_data(15 downto 9)<="0001111";
				WM_i2c_data(8 downto 0)<="000000000";
				WM_i2c_send_flag<='1';
				state_configure<=reset_off;
			when reset_off=>
				if(WM_i2c_busy='0')then
					state_configure<=idle;
				end if;
			when others => 	state_configure<=idle;
			end case;
		end if;
	end if;
end process;




--process (clock_50)
--begin
--
--	if rising_edge (clock_50)then
--		if(KEY="1111")then
--		WM_i2c_send_flag<='0';
--		end if;
--	end if;
--	
-- if rising_edge(clock_50) and WM_i2c_busy='0' then
-- 
--	
--		if (KEY(0)='0' AND SW(0)='1' ) then ----Digital Interface: DSP, 16 bit, slave mode
--		WM_i2c_data(15 downto 9)<="0000111";
--		WM_i2c_data(8 downto 0)<="000000011";	
--		WM_i2c_send_flag<='1';
--		ledR(0)<='1';
--			
--		elsif (KEY(0)='0'AND SW(1)='1' ) then---HEADPHONE VOLUME
--		WM_i2c_data(15 downto 9)<="0000000";
--		WM_i2c_data(8 downto 0)<="100011111";
--		WM_i2c_send_flag<='1';
--		ledR(1)<='1';
--		
--		elsif (KEY(0)='0'AND SW(2)='1' ) then---ADC of, DAC on, Linout ON, Power ON
--		WM_i2c_data(15 downto 9)<="0000110";
--		WM_i2c_data(8 downto 0)<="000001010";
--		WM_i2c_send_flag<='1';
--		ledR(2)<='1';
--		
--		elsif (KEY(0)='0'AND SW(3)='1' ) then---USB mode
--		WM_i2c_data(15 downto 9)<="0001000";
--		WM_i2c_data(8 downto 0)<="000000001";
--		WM_i2c_send_flag<='1';
--		ledR(3)<='1';
--		
--		elsif (KEY(0)='0'AND SW(4)='1') then---activ interface
--		WM_i2c_data(15 downto 9)<="0001001";
--		WM_i2c_data(8 downto 0)<="111111111";
--		WM_i2c_send_flag<='1';
--		ledR(4)<='1';
--		
--		elsif (KEY(0)='0'AND SW(5)='1') then---Enable DAC to LINOUT "000010010" --disable ema
--		WM_i2c_data(15 downto 9)<="0000100";
--		WM_i2c_data(8 downto 0)<="000000010";
--		WM_i2c_send_flag<='1';
--		ledR(5)<='1';
--		
--		elsif (KEY(0)='0' AND SW(6)='1') then---remove mute DAC
--		WM_i2c_data(15 downto 9)<="0000101";
--		WM_i2c_data(8 downto 0)<="000001000";
--		WM_i2c_send_flag<='1';
--		ledR(6)<='1';
--		
--		elsif (KEY(0)='0' AND SW(7)='1') then---reset
--		WM_i2c_data(15 downto 9)<="0001111";
--		WM_i2c_data(8 downto 0)<="000000000";
--		WM_i2c_send_flag<='1';
--		ledR(7)<='1';
--		
--		else
--			ledR(7 downto 0)<=(others=>'0');
--		
--		end if;
-- end if;
--end process;


end main;