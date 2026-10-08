library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity canonical_code_generate is
    port (
        clk : in  std_logic;
        reset : in  std_logic;

        start : in  std_logic;
        code_done : out std_logic;

        len_rd_addr : out std_logic_vector(7 downto 0);
        len_rd_data : in  std_logic_vector(7 downto 0);
        
        hist_rd_addr : out std_logic_vector(7 downto 0);
        hist_rd_data : in  std_logic_vector(7 downto 0); 

        dict_read_addr : in  std_logic_vector(7 downto 0);
        dict_read_data : out std_logic_vector(23 downto 0)
    );
end canonical_code_generate;

architecture Behavioral of canonical_code_generate is

    signal dict_wr_en   : std_logic := '0';
    signal dict_wr_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal dict_wr_data : std_logic_vector(23 downto 0) := (others => '0'); 
    
    type t_next_code is array (0 to 16) of unsigned(15 downto 0);
    signal next_code : t_next_code := (others => (others => '0'));

    signal main_cnt : integer range 0 to 274 := 274; 
    signal start_d  : std_logic := '0';

    signal r_code : unsigned(15 downto 0) := (others => '0');

begin

    DICTIONARY_BRAM : entity work.huffman_bram
        generic map( 
            G_RAM_WIDTH => 24,
            G_RAM_DEPTH => 256,
            G_RAM_PERFORMANCE => "LOW_LATENCY", 
            G_RAM_INIT_FILE => ""
        )
        port map( 
            addra => dict_wr_addr,   
            addrb => dict_read_addr,
            dina => dict_wr_data,
            clka => clk, 
            wea => dict_wr_en, 
            enb => '1', 
            rstb => '0', 
            regceb => '1', 
            doutb => dict_read_data  
        );

    MAIN: process(clk)
        variable v_idx : integer range 0 to 15;
        variable v_added : unsigned(15 downto 0);
        variable v_code : unsigned(15 downto 0);
        variable v_sym : integer range 0 to 255;
        variable v_len : integer range 0 to 255;
        variable v_assigned : unsigned(15 downto 0);
    begin
        if rising_edge(clk) then
            if reset = '1' then
                main_cnt  <= 0; 
                code_done <= '0';
                start_d <= '0';
                dict_wr_en <= '0';
            else
                start_d  <= start;
                dict_wr_en <= '0'; 
                code_done  <= '0';

                if start = '1' and start_d = '0' then
                    main_cnt <= 1;
                    r_code <= (others => '0');
                    next_code <= (others => (others => '0'));
                end if;

                if main_cnt >= 1 and main_cnt <= 274 then
                    
                    if main_cnt = 274 then
                        code_done <= '1';
                        main_cnt <= 0;
                    else
                        main_cnt <= main_cnt + 1;
                    end if;
                    
                    if main_cnt >= 2 and main_cnt <= 16 then
                        v_idx := main_cnt - 1; 
                        v_added := r_code + resize(unsigned(hist_rd_data), 16);
                        v_code := v_added(14 downto 0) & '0'; 

                        next_code(v_idx + 1) <= v_code; 
                        r_code <= v_code;
                    end if;

                    if main_cnt >= 18 and main_cnt <= 273 then
                        v_sym := main_cnt - 18; 
                        v_len := to_integer(unsigned(len_rd_data)); 

                        if v_len > 0 and v_len <= 16 then
                            v_assigned := next_code(v_len); 
                            dict_wr_en  <= '1';
                            dict_wr_addr <= std_logic_vector(to_unsigned(v_sym, 8));
                            dict_wr_data <= std_logic_vector(to_unsigned(v_len, 8)) & std_logic_vector(v_assigned);

                            next_code(v_len) <= v_assigned + 1;
                        else
                            dict_wr_en <= '0';
                        end if;
                    end if;

                end if;
            end if;
        end if;
    end process;
    
    hist_rd_addr <= std_logic_vector(to_unsigned(main_cnt, 8)) when (main_cnt >= 1 and main_cnt <= 15) else (others => '0');
    len_rd_addr <= std_logic_vector(to_unsigned(main_cnt - 17, 8)) when (main_cnt >= 17 and main_cnt <= 272) else (others => '0');

end Behavioral;