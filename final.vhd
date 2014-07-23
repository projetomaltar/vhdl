LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
LIBRARY lpm;
use lpm.lpm_components.all;
----------------------------------------------------------
ENTITY projeto IS
	GENERIC (
		--------------| Constantes de video |-------------
		Ha: INTEGER := 96 ; 
		Hb: INTEGER := 144; 
		Hc: INTEGER := 784;  
		Hd: INTEGER := 800;  
		Va: INTEGER := 2;    
		Vb: INTEGER := 35;   
		Vc: INTEGER := 515;  
		Vd: INTEGER := 525;
		--------------| Constantes teclado |--------------
		deb_cycles : INTEGER := 200; 
		idle_cycles: INTEGER := 3000;
		--------------------------------------------------
		ng0: INTEGER := 15;
		ng1: INTEGER := 30;
		ng2: INTEGER := 45;
		ng3: INTEGER := 59
	); 
	PORT (
		CLK,ps2clk,ps2data  : IN STD_LOGIC; 
		pixel_clk           : BUFFER STD_LOGIC; -- Clock de video
		Hsync, Vsync        : BUFFER STD_LOGIC; -- Sincronia vertical e horizontal
		R, G, B             : OUT STD_LOGIC_VECTOR( 3 DOWNTO 0); -- Define R,G e B como vetores de 4 bits(intensidade da respectiva cor)
		tecla_digitada: out BIT_VECTOR(6 downto 0) -- Vetor de 7 bits da saida do teclado
	);
End projeto;
-------------------------------------------------------------------
ARCHITECTURE comportamental OF projeto IS

	SIGNAL Hactive, Vactive, dena,COR,um_quarto_pixel_clk    : std_LOGIC;
	SIGNAL Hcount,Vcount                                     : std_logic_vector(9 downto 0);
	SIGNAL liga_mem                  						 : std_logic_vector(13 downto 0);
	SIGNAL mem_x                                             : std_logic_vector(7 downto 0);
	SIGNAL mem_y                                             : std_logic_vector(9 downto 0);
	SIGNAL Vsync_count                                       : std_logic_vector(5 downto 0);

BEGIN

	rom1: lpm_rom
	generic MAP
	(
	lpm_widthad         => 14, 
	lpm_outdata         => "unregistered",
	lpm_address_control => "registered",
	lpm_file            => "boca5.mif", 
	lpm_width           => 1) 

	PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> COR);
	--------------------------------------------------------------
	rom2: lpm_rom
	generic MAP
	(
	lpm_widthad         => 14,
	lpm_outdata         => "unregistered",
	lpm_address_control => "registered",
	lpm_file            => "boca4.mif",
	lpm_width           => 1)

	PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> COR);
	-------------------------------------------------------------------------
	rom3: lpm_rom
	generic MAP
	(
	lpm_widthad         => 14, 
	lpm_outdata         => "unregistered",
	lpm_address_control => "registered",
	lpm_file            => "boca0.mif",
	lpm_width           => 1)

	PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> COR);
	--------------------------------------------------------------
	rom4: lpm_rom
	generic MAP
	(
	lpm_widthad         => 14,
	lpm_outdata         => "unregistered",
	lpm_address_control => "registered",
	lpm_file            => "caolho.mif",
	lpm_width           => 1)

	PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> COR);

	liga_mem(13 downto 7) <= mem_y(8 downto 2); 
	liga_mem(6  downto 0) <= mem_x(6 downto 0);

	--------| Define pixel clock como metade do clock(25mhz) e o divide por 4 |---------
	Process(clk) Variable cont : Integer; 
	Begin
		IF (clk'event AND clk= '1') then
			pixel_clk <= NOT pixel_clk;
			IF (cont = 4) then
				um_quarto_pixel_clk <= NOT pixel_clk;		
				cont <= 0;
			ELSE
				cont <= cont + 1;
			END IF;
		END IF;
	end Process;
	------------------------------------------------------------------------------------

	Process (pixel_clk)
	Begin
		IF (pixel_clk'EVENT AND pixel_clk ='1')THEN
			Hcount<= Hcount + '1';
			IF (Hcount=Ha) Then
				Hsync   <= '1' ;
			ELSIF (Hcount=Hb) Then
				Hactive <= '1' ;
			ELSIF (Hcount=Hc) Then
				Hactive <= '0' ;
			ELSIF (Hcount=Hd) Then
				Hsync  <= '0' ;
				Hcount <= "0000000000";
			END IF	 ;		 
		END IF	 ;
	end Process; 

	Process (Hsync)
	Begin
		IF (Hsync'EVENT AND Hsync ='0')THEN
			Vcount <= Vcount + '1';
			IF (Vcount=Va) Then
				Vsync   <= '1' ;
			ELSIF (Vcount=Vb) Then
				Vactive <= '1' ;
			ELSIF (Vcount=Vc) Then
				Vactive <= '0' ;
			ELSIF (Vcount=Vd) Then
				Vsync  <= '0' ;
				Vcount <= "0000000000";
			END IF;		 
		END IF;
	end Process; 

	Process (Vsync) -- Sincronia Vertical
	Begin
		IF (Vsync'EVENT AND Vsync ='0')THEN
			Vsync_count <= Vsync_count + '1';
			IF (Vsync_count= 60) Then
				Vsync_count <= "000000";
			END IF;		 
		END IF;
	end Process;

	dena <= Hactive and Vactive;

	Process (Hsync,Vsync,Vactive,Hactive, dena) Variable line_counter: Integer Range 0 to Vc;
	Begin

		IF(Vsync ='0') THEN
			line_counter := 0;
		elsif (Hsync'EVENT AND Hsync ='1')then
			if(Vactive = '1') Then
			   line_counter := line_counter + 1 ;    
			end if;
		END IF;

		if (vactive='1') then
			if( line_counter >= 480)
			  then
				 mem_y <= "0000000000" ;
			  elsif (Hsync'EVENT AND Hsync ='1') THEN  
				 mem_y <= mem_y +'1' ;
			end if;
		end if;

		B <= (others => '0') ;
		R <= (others => '0') ;

		IF (dena ='1') then
			IF (Hcount  >= Hc ) then               
				mem_x <= "00000000" ;
				G <= "0000";
			ELSIF (um_quarto_pixel_clk'EVENT AND um_quarto_pixel_clk ='1') then
				mem_x <= mem_x + '1';
				IF (Vsync_count< ng0) Then
					G <= "1111";
				END IF	 ;		 
			END IF;
		else
			G <= "0000";
		END IF;

	End Process;
END comportamental; 