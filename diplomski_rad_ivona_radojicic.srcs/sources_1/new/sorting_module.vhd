library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity sorting_module is
    generic(
        num_cells : integer := 256;
        freq_bw : integer := 14;
        symbol_bw : integer := 8
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        input_symbol : in std_logic_vector(symbol_bw-1 downto 0);
        en_input : in std_logic;
        sort_valid : out std_logic;
        valid_sym_count : out std_logic_vector(8 downto 0);

        all_freqs : out std_logic_vector(num_cells*freq_bw-1 downto 0);
        all_symbols : out std_logic_vector(num_cells*symbol_bw-1 downto 0)
    );
end sorting_module;

architecture Behavioral of sorting_module is

    type freq_array is array (0 to num_cells - 1) of std_logic_vector(freq_bw-1 downto 0);
    type sym_array  is array (0 to num_cells - 1) of std_logic_vector(symbol_bw-1 downto 0);

    signal freqs : freq_array;
    signal syms : sym_array;
    
    signal matched_symbol_reg : std_logic_vector(symbol_bw-1 downto 0);
    signal updated_freq_reg : std_logic_vector(freq_bw-1 downto 0);
    
    signal shift_all : std_logic_vector(num_cells - 1 downto 0);
    signal write_all : std_logic_vector(num_cells - 1 downto 0);
    signal en_input_prev : std_logic;
    signal valid_cnt_reg : unsigned(8 downto 0) := (others => '0');
    signal match_new : std_logic;

begin

    CELL_ARRAY_GEN: for i in 0 to num_cells - 1 generate
    
        FIRST_CELL: if i = 0 generate
            cell_inst_0 : entity work.cells
                port map (
                clk => clk,
                reset => reset,
                init_symbol => (others => '0'),
                write_en => write_all(i),
                shift_en => shift_all(i),
                right_symbol => syms(i + 1),
                right_freq => freqs(i + 1),
                new_symbol => matched_symbol_reg,
                new_freq => updated_freq_reg,
                curr_symbol => syms(i),
                curr_freq => freqs(i)
                );
        end generate;

        LAST_CELL: if i = num_cells - 1 generate
            cell_inst_last : entity work.cells
                port map (
                clk => clk,
                reset => reset,
                init_symbol => std_logic_vector(to_unsigned(i, 8)),
                write_en => write_all(i),
                shift_en => shift_all(i),
                right_symbol => (others => '1'),
                right_freq => (others => '1'),
                new_symbol => matched_symbol_reg,
                new_freq => updated_freq_reg,
                curr_symbol => syms(i),
                curr_freq => freqs(i)
                );
        end generate;

        MIDDLE_CELLS: if i > 0 and i < num_cells - 1 generate
            cell_inst_mid : entity work.cells
                port map (
                clk => clk,
                reset => reset,
                init_symbol => std_logic_vector(to_unsigned(i, 8)),
                write_en => write_all(i),
                shift_en => shift_all(i),
                right_symbol => syms(i + 1),
                right_freq => freqs(i + 1),
                new_symbol => matched_symbol_reg,
                new_freq => updated_freq_reg,
                curr_symbol => syms(i),
                curr_freq => freqs(i)
                );
        end generate;

    end generate;
    
    STREAM_CONTROL: process(clk)
    begin
    if rising_edge(clk) then
        if reset = '1' then
            en_input_prev <= '0';
            valid_cnt_reg <= (others => '0');
        else
            en_input_prev <= en_input;
            if en_input = '1' and match_new = '1' then
                valid_cnt_reg <= valid_cnt_reg + 1;
            end if;
        end if;
    end if;
    end process;
    
    MAIN_CONTROL: process(input_symbol, en_input, syms, freqs)
        variable shift_mask : std_logic_vector(num_cells - 1 downto 0);   
        variable write_mask : std_logic_vector(num_cells - 1 downto 0);
 
        variable match_idx_var : integer range 0 to num_cells - 1;
        variable new_freq_var : unsigned(freq_bw-1 downto 0);
    
    begin
        shift_all <= (others => '0');
        write_all <= (others => '0');
        matched_symbol_reg <= (others => '0');
        updated_freq_reg <= (others => '0');
        match_new <= '0';
    
        shift_mask := (others => '0');
        write_mask := (others => '0');
        match_idx_var := 0;
        new_freq_var := (others => '0');
    
        if en_input = '1' then
            for i in 0 to num_cells - 1 loop
                if syms(i) = input_symbol then
                    match_idx_var := i;
                end if;
            end loop;
            
            if unsigned(freqs(match_idx_var)) = 0 then
                match_new <= '1';
            end if;

            new_freq_var := unsigned(freqs(match_idx_var)) + 1;
            
            for i in 0 to num_cells - 1 loop
                if i >= match_idx_var then
                    if new_freq_var >= unsigned(freqs(i)) then
                        shift_mask(i) := '1';
                    else
                        shift_mask(i) := '0';
                    end if;
                end if;
            end loop;
            
            shift_all <= shift_mask;
    
            for i in 0 to num_cells - 1 loop
                if i < num_cells - 1 then
                    if shift_mask(i) = '1' and shift_mask(i+1) = '0' then
                        write_mask(i) := '1';
                    else
                        write_mask(i) := '0';
                    end if;
                else
                    if shift_mask(num_cells - 1) = '1' then
                        write_mask(num_cells - 1) := '1';
                    end if;
                end if;
            end loop;
    
            write_all <= write_mask;
    
            matched_symbol_reg <= syms(match_idx_var);
            updated_freq_reg  <= std_logic_vector(new_freq_var);
    
        end if;
    
    end process;
          
    GEN_OUTPUT : for i in 0 to num_cells - 1 generate
        all_freqs((i+1)*freq_bw-1 downto i*freq_bw) <= std_logic_vector(freqs(i));
        all_symbols((i+1)*symbol_bw-1 downto i*symbol_bw) <= syms(i);
    end generate;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                sort_valid <= '0';
            elsif en_input = '0' and en_input_prev = '1' then
                sort_valid <= '1';
            end if;
        end if;
    end process;
    
    valid_sym_count <= std_logic_vector(valid_cnt_reg);
    

end Behavioral;