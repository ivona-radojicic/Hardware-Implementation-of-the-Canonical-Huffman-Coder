library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity tree_generate is
    generic(
        num_cells : integer := 256
    );
    port(
        clk : in  std_logic;
        reset : in  std_logic;
        stream_en : in  std_logic;
        input_symbols : in  std_logic_vector (7 downto 0);
        tree_addr : in  std_logic_vector (7 downto 0); 
        left_child_out : out std_logic_vector (8 downto 0);
        right_child_out : out std_logic_vector (8 downto 0);
        tree_ready : out std_logic;
        root_id : out std_logic_vector (7 downto 0)
    );
end tree_generate;

architecture Behavioral of tree_generate is
    signal sort_valid : std_logic;
    signal freqs : std_logic_vector(num_cells*14-1 downto 0);
    signal syms : std_logic_vector(num_cells*8-1 downto 0);
    signal tree_building : std_logic := '0';
   
    signal valid_sym_count : std_logic_vector(8 downto 0); 

    type ram_freqs is array (0 to 255) of unsigned(13 downto 0);
    type ram_id  is array (0 to 255) of std_logic_vector(8 downto 0);
    
    signal s_f : ram_freqs;
    signal s_id : ram_id;
    signal i_f : ram_freqs := (others => (others => '1'));
    signal i_id : ram_id  := (others => (others => '0'));
    
    signal s_ptr : unsigned(8 downto 0) := (others => '0');
    signal i_ptr : unsigned(8 downto 0) := (others => '0');
    signal write_ptr : unsigned(8 downto 0) := (others => '0');

    signal tree_wea : std_logic := '0';
    signal left_dina : std_logic_vector(8 downto 0) := (others => '0');
    signal right_dina : std_logic_vector(8 downto 0) := (others => '0');
    signal tree_addr_reg : std_logic_vector(7 downto 0) := (others => '0');
begin

    SORTER : entity work.sorting_module
    generic map( num_cells => num_cells, freq_bw => 14, symbol_bw => 8 )
    port map( 
        clk => clk, 
        reset => reset, 
        input_symbol => input_symbols,
        en_input => stream_en,
        valid_sym_count => valid_sym_count,
        sort_valid => sort_valid,
        all_freqs => freqs,
        all_symbols => syms
    );
    
    LEFT_CHILD : entity work.huffman_bram
    generic map( G_RAM_WIDTH => 9, G_RAM_DEPTH => 256, G_RAM_PERFORMANCE => "LOW_LATENCY", G_RAM_INIT_FILE => "" )
    port map( addra => tree_addr_reg, addrb => tree_addr, dina => left_dina,
              clka => clk, wea => tree_wea, enb => '1', rstb => '0', regceb => '1', doutb => left_child_out );
    
    RIGHT_CHILD : entity work.huffman_bram
    generic map( G_RAM_WIDTH => 9, G_RAM_DEPTH => 256, G_RAM_PERFORMANCE => "LOW_LATENCY", G_RAM_INIT_FILE => "" )
    port map( addra => tree_addr_reg, addrb => tree_addr, dina => right_dina,
              clka => clk, wea => tree_wea, enb => '1', rstb => '0', regceb => '1', doutb => right_child_out );
           
    SORTER_OUTPUTS: for k in 0 to num_cells - 1 generate
        s_f(k)  <= unsigned(freqs((k+1)*14-1 downto k*14));
        s_id(k) <= '0' & syms((k+1)*8-1 downto k*8); 
    end generate;

    MAIN: process(clk)
        variable s0_f, s1_f, i0_f, i1_f : unsigned(13 downto 0);
        variable s0_id, s1_id, i0_id, i1_id : std_logic_vector(8 downto 0);
        variable min1_f, min2_f : unsigned(13 downto 0);
        variable min1_id, min2_id : std_logic_vector(8 downto 0);
        variable consume_s, consume_i : integer range 0 to 2;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                s_ptr <= (others => '0'); 
                i_ptr <= (others => '0'); 
                write_ptr <= (others => '0');
                tree_wea <= '0'; 
                i_f <= (others => (others => '1'));
                tree_building <= '0';
                tree_ready <= '0';
            else
                tree_wea <= '0';

                if sort_valid = '1' and tree_building = '0' and write_ptr < unsigned(valid_sym_count) - 1 then
                    s_ptr <= to_unsigned(num_cells, 9) - unsigned(valid_sym_count);
                    i_ptr <= (others => '0');
                    write_ptr <= (others => '0');
                    tree_building <= '1';
                end if;

                if tree_building = '1' then
                    if write_ptr < (unsigned(valid_sym_count) - 1) then
                        if s_ptr < num_cells then 
                            s0_f := s_f(to_integer(s_ptr)); 
                            s0_id := s_id(to_integer(s_ptr)); 
                        else 
                            s0_f := (others => '1'); 
                            s0_id := (others => '0'); 
                        end if;
                        
                        if s_ptr + 1 < num_cells then 
                            s1_f := s_f(to_integer(s_ptr + 1)); 
                            s1_id := s_id(to_integer(s_ptr + 1)); 
                        else 
                            s1_f := (others => '1'); 
                            s1_id := (others => '0'); 
                        end if;

                        if i_ptr < write_ptr then 
                            i0_f := i_f(to_integer(i_ptr));
                            i0_id := i_id(to_integer(i_ptr)); 
                        else 
                            i0_f := (others => '1'); 
                            i0_id := (others => '0'); 
                        end if;
                        
                        if i_ptr + 1 < write_ptr then 
                            i1_f := i_f(to_integer(i_ptr + 1)); 
                            i1_id := i_id(to_integer(i_ptr + 1)); 
                        else 
                            i1_f := (others => '1'); 
                            i1_id := (others => '0'); 
                        end if;

                        if s1_f <= i0_f then
                            min1_f := s0_f; 
                            min2_f := s1_f;
                            min1_id := s0_id;
                            min2_id := s1_id;
                            consume_s := 2; 
                            consume_i := 0;
                        elsif i1_f < s0_f then
                            min1_f := i0_f; 
                            min2_f := i1_f;
                            min1_id := i0_id; 
                            min2_id := i1_id;
                            consume_s := 0; 
                            consume_i := 2;
                        else
                            consume_s := 1; 
                            consume_i := 1;
                            if s0_f <= i0_f then
                                min1_f := s0_f; 
                                min2_f := i0_f;
                                min1_id := s0_id; 
                                min2_id := i0_id;
                            else
                                min1_f := i0_f; 
                                min2_f := s0_f;
                                min1_id := i0_id; 
                                min2_id := s0_id;
                            end if;
                        end if;
                        
                        i_f(to_integer(write_ptr)) <= min1_f + min2_f;
                        i_id(to_integer(write_ptr)) <= '1' & std_logic_vector(write_ptr(7 downto 0));
                        
                        tree_addr_reg <= std_logic_vector(write_ptr(7 downto 0));
                        left_dina <= min1_id;
                        right_dina <= min2_id;
                        tree_wea <= '1';

                        write_ptr <= write_ptr + 1;
                        s_ptr <= s_ptr + consume_s;
                        i_ptr <= i_ptr + consume_i;
                    else
                        tree_building <= '0';
                        tree_ready <= '1';
                        root_id <= std_logic_vector(resize(write_ptr - 1, 8));
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;