----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/05/2025 02:42:06 PM
-- Design Name: 
-- Module Name: card_ram - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity card_ram is
    Port (
        clk      : in  std_logic;
        we       : in  std_logic;
        addr     : in  std_logic_vector(1 downto 0);   -- selects card 0 to 3
        data_in  : in  std_logic_vector(31 downto 0);  -- new PIN & balance
        data_out : out std_logic_vector(31 downto 0)   -- current PIN & balance
    );
end card_ram;

architecture Behavioral of card_ram is
    type ram_type is array (0 to 3) of std_logic_vector(31 downto 0);
    signal ram : ram_type := (
        0 => x"97360064",  -- Card 1: PIN=9736, Balance=100 
        1 => x"12340190",  -- Card 2: PIN=1234, Balance=400 
        2 => x"106207D0",  -- Card 3: PIN=1062, Balance=2000 
        3 => x"540600FA"   -- Card 4: PIN=5406, Balance=250 
    );

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                ram(to_integer(unsigned(addr))) <= data_in;
            end if;
        end if;
    end process;
    
    data_out <= ram(to_integer(unsigned(addr)));
end Behavioral;
