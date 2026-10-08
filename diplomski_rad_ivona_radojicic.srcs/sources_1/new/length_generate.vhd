library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity length_generate is
    port (
        clk : in std_logic;
        reset : in std_logic;
        tree_done : in std_logic;
        root_addr : in std_logic_vector(7 downto 0);
        left_child : in std_logic_vector(8 downto 0);
        right_child : in std_logic_vector(8 downto 0);
        tree_addr : out std_logic_vector(7 downto 0);
        code_length_addr : in std_logic_vector(7 downto 0);
        calc_done : out std_logic;
        code_length : out std_logic_vector(7 downto 0)
    );
end length_generate;

architecture Behavioral of length_generate is

    type t_stack_addr is array (0 to 255) of std_logic_vector(7 downto 0);
    type t_stack_depth is array (0 to 255) of unsigned(7 downto 0);
    signal stack_addr  : t_stack_addr;
    signal stack_depth : t_stack_depth;
    signal sp : integer range 0 to 255 := 0;

    type t_fifo is array (0 to 127) of std_logic_vector(7 downto 0);
    signal fifo_addr_even : t_fifo;
    signal fifo_addr_odd : t_fifo;
    signal fifo_depth_even : t_fifo;
    signal fifo_depth_odd : t_fifo;
    
    signal fifo_wr : unsigned(7 downto 0) := (others => '0');
    signal fifo_rd : unsigned(7 downto 0) := (others => '0');

    signal done_reg : std_logic := '0';
    signal eval_running : std_logic := '0';

    signal bram_valid : std_logic := '0'; 
    signal tree_done_d : std_logic := '0'; 
    
    signal len_wea : std_logic := '0';
    signal len_addra : std_logic_vector(7 downto 0);
    signal len_dina : std_logic_vector(7 downto 0);
    
    signal eval_depth : unsigned(7 downto 0) := (others => '0');

begin

    LENGTH_BRAM : entity work.huffman_bram
        generic map( 
            G_RAM_WIDTH => 8, 
            G_RAM_DEPTH => 256, 
            G_RAM_PERFORMANCE => "LOW_LATENCY", 
            G_RAM_INIT_FILE => "" 
        )
        port map( 
            addra => len_addra, 
            addrb => code_length_addr, 
            dina => len_dina,
            clka => clk, 
            wea => len_wea, 
            enb => '1', 
            rstb => '0', 
            regceb => '1', 
            doutb => code_length 
        );

    MAIN: process(clk)
        variable v_wr_idx : integer range 0 to 127;
        variable v_wr_idx_next : integer range 0 to 127;
        variable v_rd_idx : integer range 0 to 127;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                eval_running <= '0';
                bram_valid  <= '0';
                eval_depth <= (others => '0');
                sp <= 0;
                done_reg <= '0';
                fifo_wr <= (others => '0');
                fifo_rd  <= (others => '0');
                len_wea <= '0';
                tree_addr <= (others => '0');
                tree_done_d  <= '0';
            else
                tree_done_d <= tree_done;
                v_wr_idx := to_integer(fifo_wr(7 downto 1));
                if v_wr_idx = 127 then
                    v_wr_idx_next := 0;
                else
                    v_wr_idx_next := v_wr_idx + 1;
                end if;
                
                v_rd_idx := to_integer(fifo_rd(7 downto 1));

                if fifo_rd /= fifo_wr then
                    len_wea <= '1';
                    if fifo_rd(0) = '0' then
                        len_addra <= fifo_addr_even(v_rd_idx);
                        len_dina <= fifo_depth_even(v_rd_idx);
                    else
                        len_addra <= fifo_addr_odd(v_rd_idx);
                        len_dina <= fifo_depth_odd(v_rd_idx);
                    end if;
                    fifo_rd <= fifo_rd + 1;
                else
                    len_wea <= '0';
                end if;

                if tree_done = '1' and tree_done_d = '0' then
                    eval_running <= '1';
                    bram_valid <= '0'; 
                    tree_addr <= root_addr;
                    eval_depth <= (others => '0');
                    sp <= 0;
                    done_reg <= '0';
                    fifo_wr <= (others => '0');
                    fifo_rd <= (others => '0');

                elsif eval_running = '1' then
                    if bram_valid = '0' then
                        bram_valid <= '1';
                    else
                        bram_valid <= '0';
                        if left_child(8) = '0' and right_child(8) = '0' then
                            if fifo_wr(0) = '0' then
                                fifo_addr_even(v_wr_idx) <= left_child(7 downto 0);
                                fifo_depth_even(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                                
                                fifo_addr_odd(v_wr_idx) <= right_child(7 downto 0);
                                fifo_depth_odd(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                            else
                                fifo_addr_odd(v_wr_idx) <= left_child(7 downto 0);
                                fifo_depth_odd(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                                
                                fifo_addr_even(v_wr_idx_next) <= right_child(7 downto 0);
                                fifo_depth_even(v_wr_idx_next) <= std_logic_vector(eval_depth + 1);
                            end if;
                            
                            fifo_wr <= fifo_wr + 2;
                            
                            if sp > 0 then
                                sp        <= sp - 1;
                                tree_addr  <= stack_addr(sp - 1);
                                eval_depth <= stack_depth(sp - 1);
                            else
                                eval_running <= '0';
                            end if;

                        elsif left_child(8) = '0' then
                            if fifo_wr(0) = '0' then
                                fifo_addr_even(v_wr_idx) <= left_child(7 downto 0);
                                fifo_depth_even(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                            else
                                fifo_addr_odd(v_wr_idx) <= left_child(7 downto 0);
                                fifo_depth_odd(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                            end if;
                            fifo_wr <= fifo_wr + 1;
                            
                            tree_addr  <= right_child(7 downto 0);
                            eval_depth <= eval_depth + 1;

                        elsif right_child(8) = '0' then
                            if fifo_wr(0) = '0' then
                                fifo_addr_even(v_wr_idx) <= right_child(7 downto 0);
                                fifo_depth_even(v_wr_idx) <= std_logic_vector(eval_depth + 1);
                            else
                                fifo_addr_odd(v_wr_idx) <= right_child(7 downto 0);
                                fifo_depth_odd(v_wr_idx)  <= std_logic_vector(eval_depth + 1);
                            end if;
                            fifo_wr <= fifo_wr + 1;
                            
                            tree_addr  <= left_child(7 downto 0);
                            eval_depth <= eval_depth + 1;

                        else
                            stack_addr(sp) <= right_child(7 downto 0);
                            stack_depth(sp) <= eval_depth + 1;
                            sp <= sp + 1;
                            
                            tree_addr <= left_child(7 downto 0);
                            eval_depth <= eval_depth + 1;
                        end if;
                    end if;
                end if;
                if eval_running = '0' and tree_done_d = '1' and fifo_rd = fifo_wr then
                    done_reg <= '1';
                end if;

            end if;
        end if;
    end process;

    calc_done <= done_reg;

end Behavioral;