library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity histogram_generate is
    port (
        clk : in std_logic;
        reset : in std_logic;

        start : in std_logic;
        hist_done : out std_logic;
        
        len_addr : out std_logic_vector(7 downto 0);
        len_data : in std_logic_vector(7 downto 0);
        
        hist_read_addr : in std_logic_vector(7 downto 0);
        hist_read_data : out std_logic_vector(7 downto 0) 
    );
end histogram_generate;

architecture Behavioral of histogram_generate is

    type t_hist_array is array (0 to 255) of unsigned(7 downto 0);
    signal hist_mem : t_hist_array := (others => (others => '0'));
    
    signal addr_cnt : integer range 0 to 256 := 256; 
    
    signal start_d : std_logic := '0';
    signal valid_d1 : std_logic := '0';
    signal hist_wea : std_logic := '0';
    signal hist_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal hist_dina : std_logic_vector(7 downto 0) := (others => '0');

begin

    HISTOGRAM_BRAM : entity work.huffman_bram
    generic map( 
        G_RAM_WIDTH => 8, 
        G_RAM_DEPTH => 256, 
        G_RAM_PERFORMANCE => "LOW_LATENCY", 
        G_RAM_INIT_FILE => "" 
    )
    port map( 
        addra => hist_addr, 
        addrb => hist_read_addr,
        dina => hist_dina,
        clka => clk, 
        wea => hist_wea, 
        enb => '1', 
        rstb => '0', 
        regceb => '1', 
        doutb => hist_read_data  
    );

    len_addr <= std_logic_vector(to_unsigned(addr_cnt, 8)) when addr_cnt < 256 else (others => '0');

    MAIN : process(clk)
        variable v_len : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                addr_cnt <= 256;
                valid_d1 <= '0';
                hist_done <= '0';
                start_d  <= '0';
                hist_mem <= (others => (others => '0'));
                hist_wea <= '0';
                hist_addr <= (others => '0');
                hist_dina <= (others => '0');
            else
                start_d <= start;
                valid_d1 <= '0';
                hist_done <= '0';
                hist_wea <= '0'; 
                
                if start = '1' and start_d = '0' then
                    addr_cnt <= 0;                   
                    hist_mem <= (others => (others => '0'));    
                elsif addr_cnt < 256 then
                    addr_cnt <= addr_cnt + 1;
                    valid_d1 <= '1'; 
                end if;

                if valid_d1 = '1' then
                    v_len := to_integer(unsigned(len_data));
                    hist_mem(v_len) <= hist_mem(v_len) + 1;
                    hist_addr <= len_data;
                    hist_dina <= std_logic_vector(hist_mem(v_len) + 1);
                    hist_wea  <= '1';
                    if addr_cnt = 256 then
                        hist_done <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;