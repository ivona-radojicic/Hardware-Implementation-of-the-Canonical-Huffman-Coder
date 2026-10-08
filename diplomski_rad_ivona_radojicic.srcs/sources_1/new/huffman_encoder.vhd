library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity huffman_encoder is
    generic(
        num_cells : integer := 256
    );
    port(
        clk : in std_logic;
        reset : in std_logic;
        button : in std_logic;
        tx_out : out std_logic;
        tx_done : out std_logic
    );
end huffman_encoder;

architecture Behavioral of huffman_encoder is

    component clk_wiz_0
    port (
        clk_in1  : in std_logic;
        reset    : in std_logic;
        locked   : out std_logic;
        clk_out1 : out std_logic
    );
    end component;

    signal button_edge : std_logic;
    signal sig_stream_en : std_logic;
    signal sig_symbols : std_logic_vector(7 downto 0);
    signal sig_done  : std_logic;
    signal is_canonical_phase : std_logic := '0';
    
    signal tree_ready : std_logic;
    signal root_id : std_logic_vector(7 downto 0);
    signal left_child : std_logic_vector(8 downto 0);
    signal right_child : std_logic_vector(8 downto 0);
    signal tree_address : std_logic_vector(7 downto 0):= (others => '0');

    signal calc_done : std_logic;
    signal code_length : std_logic_vector(7 downto 0);
    signal code_length_addr : std_logic_vector(7 downto 0); 
    signal length_start : std_logic;

    signal len_addr_hist : std_logic_vector(7 downto 0);
    signal len_addr_canon : std_logic_vector(7 downto 0);

    signal hist_done : std_logic;
    signal hist_read_addr : std_logic_vector(7 downto 0);
    signal hist_read_data : std_logic_vector(7 downto 0);

    signal code_done : std_logic;
    signal dict_read_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal dict_read_data : std_logic_vector(23 downto 0);

    signal tx_dvalid : std_logic := '0';
    signal tx_data : std_logic_vector(7 downto 0) := (others => '0');
    signal tx_busy : std_logic;
    
    signal tree_gen_addr : std_logic_vector(7 downto 0) := (others => '0');
    signal code_gen_addr : std_logic_vector(7 downto 0):= (others => '0');
    
    signal sending : std_logic := '0';
    signal tx_req : std_logic := '0';
    signal sym_counter : unsigned(7 downto 0) := (others => '0');
    signal byte_cnt : unsigned(1 downto 0) := "10";
    
    signal clk_40mhz : std_logic;
    signal locked_sig : std_logic;
    signal sys_reset : std_logic;

begin

    sys_reset <= reset OR (not locked_sig);

    CLOCK_WIZ_INST : clk_wiz_0
    port map (
        clk_in1 => clk,         
        reset => reset,      
        locked  => locked_sig,  
        clk_out1 => clk_40mhz    
    );

    TREE_GENERATE_INST : entity work.tree_generate
    generic map(
        num_cells => num_cells
    )
    port map(
        clk  => clk_40mhz,
        reset => sys_reset,
        stream_en => sig_stream_en, 
        input_symbols  => sig_symbols,
        tree_addr => tree_address, 
        left_child_out => left_child,
        right_child_out => right_child,
        tree_ready => tree_ready,
        root_id  => root_id
    );
    
    TEXT_FILE_INST : entity work.text_file
    generic map (
        G_ROM_DEPTH => 5000,
        G_INIT_FILE => "C:/Users/radoj/OneDrive/Desktop/huffman/rom_init.txt" 
    )
    port map (
        clk => clk_40mhz,
        reset => sys_reset,
        start_btn => button_edge,    
        stream_en => sig_stream_en,   
        input_symbols => sig_symbols, 
        transfer_done => sig_done
    );
    
    LENGTH_GENERATE_INST : entity work.length_generate
    port map(
        clk => clk_40mhz,
        reset => sys_reset,
        tree_done => length_start,
        root_addr => root_id,
        left_child  => left_child,
        right_child => right_child,
        tree_addr => code_gen_addr,
        code_length_addr => code_length_addr, 
        calc_done => calc_done,
        code_length => code_length
    );
    
    HISTOGRAM_GENERATE_INST : entity work.histogram_generate
    port map(
        clk => clk_40mhz,
        reset => sys_reset,
        start => calc_done,
        hist_done => hist_done,
        len_addr => len_addr_hist,  
        len_data => code_length,
        hist_read_addr => hist_read_addr,
        hist_read_data => hist_read_data 
    );
    
    CANONICAL_CODE_GENERATE_INST : entity work.canonical_code_generate
    port map(
        clk => clk_40mhz,
        reset => sys_reset,
        start => hist_done,
        code_done  => code_done,
        len_rd_addr => len_addr_canon, 
        len_rd_data => code_length,
        hist_rd_addr => hist_read_addr,
        hist_rd_data  => hist_read_data,
        dict_read_addr => dict_read_addr, 
        dict_read_data => dict_read_data  
    );
    
    EDGE_MAP : entity work.edge_detector
    port map (
        clk => clk_40mhz,
        reset => sys_reset,
        button => button,
        edge => button_edge
    );
    
    UART_TX_INST : entity work.uart_tx
    generic map (
        CLK_FREQ => 40,     
        SER_FREQ => 115200
    )
    port map (
        clk => clk_40mhz,
        rst => sys_reset,
        tx => tx_out,
        par_en => '0',
        tx_dvalid => tx_dvalid,
        tx_data => tx_data,
        tx_busy => tx_busy
    );
    
    code_length_addr <= len_addr_canon when is_canonical_phase = '1' else len_addr_hist;

    dict_read_addr <= std_logic_vector(sym_counter);
    
    tree_address <= tree_gen_addr when tree_ready = '0' else code_gen_addr;

    tx_data <= dict_read_data(23 downto 16) when byte_cnt = "10" else
               dict_read_data(15 downto 8)  when byte_cnt = "01" else
               dict_read_data(7 downto 0);

    tx_dvalid <= tx_req;

    MULTIPLEX_ADDR: process(clk_40mhz)
    begin
        if rising_edge(clk_40mhz) then
            if sys_reset = '1' then 
                is_canonical_phase <= '0';
            elsif hist_done = '1' then
                is_canonical_phase <= '1'; 
            elsif code_done = '1' then
                is_canonical_phase <= '0'; 
            end if;
        end if;
    end process;
    
    UART_SENDING : process(clk_40mhz)
    begin
    if rising_edge(clk_40mhz) then
        if sys_reset = '1' then  
            tx_req <= '0';
            tx_done <= '0';
            sym_counter  <= (others => '0');
            byte_cnt <= "10";
            sending <= '0';
        else
            if code_done = '1' and sending = '0' and sys_reset = '0' then 
                sending <= '1';
                byte_cnt <= "10";
                tx_req <= '0';
                tx_done <= '0';
                sym_counter  <= (others => '0');
            end if;
            
            if sending = '1' then
                if tx_req = '0' and tx_busy = '0' then
                    tx_req <= '1';
                end if;

                if tx_req = '1' and tx_busy = '1' then
                    tx_req <= '0';

                    if byte_cnt = "00" then
                        byte_cnt <= "10"; 
                        
                        if sym_counter = 255 then
                            sending <= '0'; 
                            tx_done    <= '1';
                        else
                            sym_counter <= sym_counter + 1; 
                        end if;
                    else
                        byte_cnt <= byte_cnt - 1; 
                    end if;
                end if;
            end if;
        end if;
    end if;
    end process;

    length_start <= tree_ready;

end Behavioral;