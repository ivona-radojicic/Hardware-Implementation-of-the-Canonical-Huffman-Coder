library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;

entity cells is
    port(
        clk: in std_logic;
        reset: in std_logic;
        init_symbol: in std_logic_vector(7 downto 0);
        
        write_en: in std_logic;
        shift_en: in std_logic;
        
        right_symbol: in std_logic_vector(7 downto 0);
        right_freq: in std_logic_vector(13 downto 0);
        
        curr_symbol: out std_logic_vector(7 downto 0);
        curr_freq: out std_logic_vector(13 downto 0);
        
        new_symbol: in std_logic_vector(7 downto 0);
        new_freq: in std_logic_vector(13 downto 0)
    );
end cells;

architecture Behavioral of cells is

    signal r_symbol : std_logic_vector(7 downto 0) := (others => '0');
    signal r_freq : std_logic_vector(13 downto 0) := (others => '0');

begin

    CELL_LOGIC: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                r_freq <= (others => '0');
                r_symbol <= init_symbol;
            else
                if write_en = '1' then
                    r_freq <= new_freq;
                    r_symbol <= new_symbol;
                elsif shift_en = '1' then
                    r_freq <= right_freq;
                    r_symbol <= right_symbol;
                else
                    r_symbol <= r_symbol;
                    r_freq <= r_freq;
                end if;
            end if;
        end if;
    end process;
    
    OUTPUT_LOGIC: process(r_symbol, r_freq)
    begin
        curr_freq <= r_freq;
        curr_symbol <= r_symbol;
    end process;


end Behavioral;
