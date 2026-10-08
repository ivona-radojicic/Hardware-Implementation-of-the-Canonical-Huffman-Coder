library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library work;

entity huffman_encoder_tb is
end huffman_encoder_tb;

architecture Behavioral of huffman_encoder_tb is

    component huffman_encoder
    generic(
        num_cells : integer := 256
    );
    port(
        clk     : in std_logic;
        reset   : in std_logic;
        button  : in std_logic;
        tx_out  : out std_logic;
        tx_done : out std_logic
    );
    end component;

    signal clk     : std_logic := '0';
    signal reset   : std_logic := '0';
    signal button  : std_logic := '0';
    signal tx_out  : std_logic;
    signal tx_done : std_logic;

    -- Klok period za 125 MHz 
    constant clk_period : time := 8 ns;

begin

    uut: entity work.huffman_encoder 
    generic map (
        num_cells => 256
    )
    port map (
        clk => clk,
        reset => reset,
        button => button,
        tx_out => tx_out,
        tx_done => tx_done
    );

    clk_process :process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin		
        reset <= '1';
        button <= '0';
        wait for 100 ns;    
        reset <= '0';
        
        -- Sačekaj da Clock Wizard oživi i stabilizuje takt!
        wait for 2 ms;  -- <--- DODAJ OVO
        
        -- Tek sada pritisni taster
        button <= '1';
        wait for 10 us; 
        button <= '0';
        
        -- Čekamo da se završi streaming svih podataka (256 * 3 bajta)
        -- Na 500,000 bps ovo traje oko 15.3 milisekundi
        wait until tx_done = '1';
        
        wait for 1 ms; 
        
        assert false report "Simulacija zavrsena! UART streaming odradjen. " severity failure;
    end process;

end Behavioral;