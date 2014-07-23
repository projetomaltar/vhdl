ENTITY ps2_keyboard IS
 Generic (
          deb_cycles: INTEGER := 200; -- 4us for debouncer (@ 50MHz)
			 idle_cycles: INTEGER := 3000); -- 60us >1\2 period ps2_clk )
			 
 PORT ( 
       clk: in BIT;  -- system clock (50MHz)
		 ps2clk: in bit; -- clk from keyboard ( 10-17 khz)
		 ps2data: in bit; -- data from keyboard
		 ssd: out BIT_VECTOR(6 downto 0)); -- data out to ssd
END ps2_keyboard;

----------------------------------------------------------------------

ARCHITECTURE ps2_keyboard OF ps2_keyboard IS
  signal deb_ps2clk : bit;         -- debounced ps2_clk
  signal deb_ps2data : bit;        -- debounced ps2_data
  signal data, dout : bit_vector( 10 downto 0);
  signal idle: bit; -- '1' means data line is idle
  signal error: bit; -- '1' when start, stop, or parity wrong
  
  Begin
  
   ---------- debouncer for ps2clk ---------------------------------
	process(clk)
	 variable count: integer range 0 to deb_cycles;
	begin
    if(clk'event and clk = '1') then
	    if ( deb_ps2clk =ps2clk) then
		   count := 0 ;
		 else
		   count := count + 1 ;
		   if (count = deb_cycles) then
		       deb_ps2clk <= ps2clk ;
				 count := 0 ; 
		   end if;		 
		 end if;
	 end if;
    end process;
	 
   ---------- debouncer for ps2data ---------------------------------
	process(clk)
	 variable count: integer range 0 to deb_cycles;
	begin
    if(clk'event and clk = '1') then
	    if ( deb_ps2data =ps2data) then
		   count := 0 ;
		 else
		   count := count + 1 ;
		   if (count = deb_cycles) then
		       deb_ps2data <= ps2data ;
				 count := 0 ; 
		   end if;		 
		 end if;
	 end if;
    end process;	 
	 
 ----------- Detection of idle state---------------------------------
 
 process(clk)
  variable count: integer range 0 to idle_cycles;
  
 begin
    if(clk'event and clk = '0') then
	    if ( deb_ps2data = '0') then
		   idle <= '0' ;
		   count := 0 ;
		 elsif  (deb_ps2clk= '1') then
		  count := count +1;
		  if ( count = idle_cycles ) then
		   idle <= '1' ;
		  end if;
		 else
		  count := 0 ;
		 end if;
	end if;	 
end process;
 
 ------------ Receiving data from keyboard -------------------------
 
 process ( deb_ps2clk)
  variable i: integer range 0 to 15;
 begin
  if(deb_ps2clk'event and deb_ps2clk = '0') then
   if( idle='1') then
	 i:= 0;
   else 
	  data(i) <= deb_ps2data;
	  i:= i + 1 ;
	  if ( i = 11)then
	   i := 0 ;
		dout <= data;
	  end if;
	end if;
  end if;	
 end process;

----------- checking for erros -----------------------------------
process(dout)
begin
 if( dout(0) = '0' and dout(10) ='1' and 
   ( dout(1) xor dout(2) xor dout(3) xor dout(4) xor dout(5) xor 
     dout(6) xor dout(7) xor dout(8) xor dout(9) )= '1') then
	error <= '0' ;
 else
   error <= '1' ; 
 end if ;
end process;

---------- ssd driver --------------------------------------------

process (dout, error)
begin
 if (error ='0') then
   case  dout( 8 downto 1) is
	 when "01000101" => ssd <= "0000001"; -- "0" on ssd
	 when "00010110" => ssd <= "1001111"; -- "1" on ssd
	 when "00011110" => ssd <= "0010010"; -- "2" on ssd
	 when "00100110" => ssd <= "0000110"; -- "3" on ssd
	 when "00100101" => ssd <= "1001100"; -- "4" on ssd
	 when "00101110" => ssd <= "0100100"; -- "5" on ssd
	 when "00110110" => ssd <= "0100000"; -- "6" on ssd
	 when "00111101" => ssd <= "0001111"; -- "7" on ssd
	 when "00111110" => ssd <= "0000000"; -- "8" on ssd
	 when "01000110" => ssd <= "0000100"; -- "9" on ssd	 
	 when "11110000" => ssd <= "1111111"; -- blank on ssd	 
	 when others     => ssd <= "0010000"; -- "e" on ssd
  end case;
 else  
  ssd <= "0110000"; -- "E" on ssd
 end if;
end process;

END ps2_keyboard; 
 