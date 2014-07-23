----------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
LIBRARY lpm;
use lpm.lpm_components.all;
----------------------------------------------------------------
ENTITY video_3 IS
    GENERIC (
	     Ha: INTEGER := 96 ;  -- Hpulse
	     Hb: INTEGER := 144;  -- Hpulse + HBP
	     Hc: INTEGER := 784;  -- Hpulse + HBP + Hactive
	     Hd: INTEGER := 800;  -- Hpulse + HBP + Hactive + HFP
	     Va: INTEGER := 2;    -- Vpulse
	     Vb: INTEGER := 35;   -- Vpulse + VBP
	     Vc: INTEGER := 515;  -- Vpulse + VBP + Vactive
	     Vd: INTEGER := 525;
		  ng0: integer:= 15;
		  ng1: integer:= 30;
		  ng2: integer:= 45;
		  ng3: integer:= 59
		  ); -- Vpulse + VBP + Vactive + VFP
   PORT (
	       CLK      : IN STD_LOGIC; --50MHz disponivel na placa
	       pixel_clk: BUFFER STD_LOGIC;
            Hsync, Vsync: BUFFER STD_LOGIC;
		 R, G, B: OUT STD_LOGIC_VECTOR( 3 DOWNTO 0) --modificado para placa E1 
			                                    -- DAC com 4bits
	 );
End 	video_3;
-------------------------------------------------------------------
ARCHITECTURE comportamental OF video_3 IS

 SIGNAL Hactive, Vactive, dena: std_LOGIC;
 signal Hcount: std_logic_vector(9 downto 0);--
 signal Vcount: std_logic_vector(9 downto 0);--
 signal liga_mem: std_logic_vector(13 downto 0);--14 modificado maltar
 SIGNAL COR_rom0:STD_LOGIC_vector( 0 downto 0);-- modificado
 SIGNAL COR_rom1:STD_LOGIC_vector( 0 downto 0);-- modificado
 SIGNAL COR_rom2:STD_LOGIC_vector( 0 downto 0);-- modificado
 SIGNAL COR_rom3:STD_LOGIC_vector( 0 downto 0);-- modificado
 signal metade_pixel_clk: std_logic;
 signal um_quarto_pixel_clk: std_logic;
 signal mem_x: std_logic_vector(7 downto 0);
 signal mem_y: std_logic_vector(9 downto 0);
 signal Vsync_count:  std_logic_vector(5 downto 0);

 begin

 myrom0: lpm_rom
 generic MAP
 (
  lpm_widthad         => 14, --modificado maltar
  lpm_outdata         => "unregistered",
  lpm_address_control => "registered",
  lpm_file            => "boca5.mif", -- data file
  lpm_width           => 1) -- data width
 
 PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> cor_rom0);
--------------------------------------------------------------
 myrom1: lpm_rom
 generic MAP
 (
  lpm_widthad         => 14, --modificado maltar
  lpm_outdata         => "unregistered",
  lpm_address_control => "registered",
  lpm_file            => "boca4.mif", -- data file
  lpm_width           => 1) -- data width
 
 PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> cor_rom1);
-------------------------------------------------------------------------
 myrom2: lpm_rom
 generic MAP
 (
  lpm_widthad         => 14, --modificado maltar
  lpm_outdata         => "unregistered",
  lpm_address_control => "registered",
  lpm_file            => "boca0.mif", -- data file
  lpm_width           => 1) -- data width
 
 PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> cor_rom2);
--------------------------------------------------------------
 myrom3: lpm_rom
 generic MAP
 (
  lpm_widthad         => 14, --modificado maltar
  lpm_outdata         => "unregistered",
  lpm_address_control => "registered",
  lpm_file            => "caolho.mif", -- data file
  lpm_width           => 1) -- data width
 
 PORT MAP( inclock => pixel_clk, address=> liga_mem, q=> cor_rom3);


-- Reparem como foi feito a transformacao de x-y , para uma dimensao
liga_mem(13 downto 7) <= mem_y(8 downto 2); -- modificado maltar
liga_mem(6  downto 0) <= mem_x(6 downto 0);
------------------------------------------------------------------
---PART 1 : CONTROL GENERATOR
------------------------------------------------------------------

-- Create pixel clock ( 50MHz -> 25MHz)
Process(clk)
BEGIN
  IF (clk'event AND clk= '1') then
    pixel_clk <= NOT pixel_clk;
  END IF	 ;
end Process;

-- Create metade pixel clock/ 2 ( 25MHz -> 12.5MHz)
Process(clk)
BEGIN
  IF (pixel_clk'event AND pixel_clk= '1') then
      metade_pixel_clk <= NOT metade_pixel_clk;
  END IF	 ;
end Process;

-- Create um_quarto_pixel clock (12.50MHz -> 6.25MHz)
Process(clk)
BEGIN
  IF (metade_pixel_clk'event AND metade_pixel_clk= '1') then
      um_quarto_pixel_clk <= NOT um_quarto_pixel_clk;
  END IF	 ;
end Process;

----- create contador de linhas ;

--------------------------------------------
-- Horizontal signals generation:
Process (pixel_clk)
--Variable Hcount: Integer Range 0 to Hd;
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

-- Vertical signals generation:
Process (Hsync)
 --Variable Vcount: Integer Range 0 to Vd;
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
   END IF	 ;		 
 END IF	 ;
end Process; 
-----------------------------------

-- contador de Vsync , necessario para animacao da figura
Process (Vsync)
 --Variable Vcount: Integer Range 0 to Vd;
Begin
IF (Vsync'EVENT AND Vsync ='0')THEN
   Vsync_count <= Vsync_count + '1';
   IF (Vsync_count= 60) Then
            Vsync_count <= "000000";
   END IF	 ;		 
 END IF	 ;
end Process;


-- dISPLAY ENABLE GENERATION:
dena <= Hactive and Vactive;
------------------------------------------------------------
-- Part 2: Image Generator
------------------------------------------------------------
Process ( Hsync,Vsync,Vactive,Hactive, dena,COR_rom0,cor_rom1) --ed_switch, green_switch, blue_switch )
Variable line_counter: Integer Range 0 to Vc ;
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
-- fixando outras cores. Na verdade sem cor.
 B <= (others => '0') ;
 R <= (others => '0') ;
 
IF (dena ='1') then
  if (Hcount  >= Hc ) -- isto , maior que 784, ou
    then              -- fim do pulso de Hactive.   
	 mem_x <= "00000000" ;
	 G(0)  <= '0' ;
	 G(1)  <= '0' ;
	 G(2)  <= '0' ;
	 G(3)  <= '0' ;
--	 elsif (metade_pixel_clk'event and metade_pixel_clk ='1') then
   elsif (um_quarto_pixel_clk'EVENT AND um_quarto_pixel_clk ='1')THEN
         mem_x <= mem_x + '1';
      --   if ( Vsync_count < 30 )
      --      then
       --       G(0)  <= COR_rom0(0);
        --      G(1)  <= COR_rom0(0);
        --      G(2)  <= COR_rom0(0);
        --      G(3)  <= COR_rom0(0);
         --  else
         --     G(0)  <= COR_rom1(0);
         --     G(1)  <= COR_rom1(0);
         --     G(2)  <= COR_rom1(0);
         --     G(3)  <= COR_rom1(0);
       -- end if;
		 -- Natalia - gustavo ----
	
   IF (Vsync_count< ng0) Then
	          G(0)  <= COR_rom0(0);
             G(1)  <= COR_rom0(0);
             G(2)  <= COR_rom0(0);
             G(3)  <= COR_rom0(0);
   ELSIF (Vsync_count>= ng0 and Vsync_count < ng1) Then
	          G(0)  <= COR_rom1(0);
             G(1)  <= COR_rom1(0);
             G(2)  <= COR_rom1(0);
             G(3)  <= COR_rom1(0);
   ELSIF (Vsync_count >= ng1 and Vsync_count < ng2) Then
	          G(0)  <= COR_rom2(0);
             G(1)  <= COR_rom2(0);
             G(2)  <= COR_rom2(0);
             G(3)  <= COR_rom2(0);
   ELSIF ( Vsync_count >= ng2 and Vsync_count< ng3) Then
	          G(0)  <= COR_rom3(0);
             G(1)  <= COR_rom3(0);
             G(2)  <= COR_rom3(0);
             G(3)  <= COR_rom3(0);
   END IF	 ;		 
 --END IF	 ;
		 -- natalia gustavo -fim -----
  end if;
  else
    -- sem cor ;
    G(0) <= '0';
    G(1) <= '0';
    G(2) <= '0';
    G(3) <= '0';
END IF;

End Process;
ENd comportamental; 
 
	
  
		 
