library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;
library work;

entity text_file is
    generic (
        G_ROM_DEPTH : integer := 5000;
        G_INIT_FILE : string := "C:\Users\radoj\OneDrive\Desktop\huffman\rom_init.txt"
    );
    port (
        clk : in std_logic;
        reset : in std_logic;
        start_btn : in std_logic;
        
        stream_en : out std_logic;
        input_symbols : out std_logic_vector(7 downto 0);
        transfer_done : out std_logic
    );
end text_file;

architecture Behavioral of text_file is

    type rom_type is array (0 to G_ROM_DEPTH-1) of std_logic_vector (7 downto 0);
    
    impure function initramfromfile (ramfilename : in string) return rom_type is
        file ramfile : text;
        variable ramfileline : line;
        variable ram_name : rom_type := (others => (others => '0'));
        variable bitvec : bit_vector(7 downto 0);
    begin
        if ramfilename /= "" then
            file_open(ramfile, ramfilename, read_mode);
            for i in 0 to G_ROM_DEPTH-1 loop
                if not endfile(ramfile) then
                    readline(ramfile, ramfileline);
                    read(ramfileline, bitvec);
                    ram_name(i) := to_stdlogicvector(bitvec);
                end if;
            end loop;
            file_close(ramfile);
        end if;
        return ram_name;
    end function;

    signal text_rom : rom_type := initramfromfile(G_INIT_FILE);
    signal addr_cnt : unsigned(15 downto 0) := (others => '0');
    signal sending  : std_logic := '0';
    signal rom_data_out : std_logic_vector(7 downto 0) := (others => '0');

begin

    MAIN : process(clk)
    begin
        if rising_edge(clk) then
            if to_integer(addr_cnt) < G_ROM_DEPTH then
                    rom_data_out <= text_rom(to_integer(addr_cnt));
                else
                    rom_data_out <= (others => '0');
                end if;
            if reset = '1' then
                addr_cnt <= (others => '0');
                sending <= '0';
                stream_en <= '0';
                transfer_done <= '0';
                input_symbols <= (others => '0');
            else
                stream_en <= '0';
                if start_btn = '1' and sending = '0' then
                    sending <= '1';
                    addr_cnt <= (others => '0');
                    transfer_done <= '0';
                end if;

                if sending = '1' then
                    if addr_cnt < G_ROM_DEPTH then
                        input_symbols <= rom_data_out;
                        stream_en <= '1';
                        addr_cnt <= addr_cnt + 1;
                    else
                        sending <= '0';
                        transfer_done <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process;

end Behavioral;