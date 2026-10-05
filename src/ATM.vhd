----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 06/01/2025 03:22:47 PM
-- Design Name: 
-- Module Name: ATM - Behavioral
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
use IEEE.std_logic_unsigned.ALL;
use IEEE.numeric_std.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ATM is
    Port ( clk : in STD_LOGIC;
           sel_op : in STD_LOGIC_VECTOR (1 downto 0);
           bill : in std_logic_vector(2 downto 0);
           load : in STD_LOGIC;
           add : in std_logic;
           confirm : in STD_LOGIC;
           confirm_pin : in std_logic;
           card_nr : in std_logic_vector(1 downto 0);
           sw : in std_logic_vector(3 downto 0);
           led : out std_logic;
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end ATM;

architecture Behavioral of ATM is

component MPG is
    Port ( btn : in STD_LOGIC;
           clk : in STD_LOGIC;
           en : out STD_LOGIC);
end component;

component card_ram is
    Port (
        clk      : in  std_logic;
        we       : in  std_logic;
        addr     : in  std_logic_vector(1 downto 0);   -- selects card 0 to 3
        data_in  : in  std_logic_vector(31 downto 0);  -- new PIN & balance
        data_out : out std_logic_vector(31 downto 0)   -- current PIN & balance
    );
end component;

component SSD is
    Port ( clk : in std_logic;
           digits: in std_logic_vector(15 downto 0);
           an : out STD_LOGIC_VECTOR(3 downto 0);
           cat : out STD_LOGIC_VECTOR(6 downto 0));
end component;


signal display     : std_logic_vector(15 downto 0);
signal load_en     : std_logic; --btn
signal confirm_en  : std_logic; --btn
signal confirm_pin_en : std_logic; --btn for
signal add_en      : std_logic; --btn sum/ withdraw
signal ram_in      : std_logic_vector(31 downto 0);  
signal ram_out     : std_logic_vector(31 downto 0);  
signal pin         : std_logic_vector(15 downto 0) := x"0000";
signal new_pin     : std_logic_vector(15 downto 0);
signal pin_confirm : std_logic_vector(15 downto 0) := x"0000";
signal pin_display : std_logic_vector(15 downto 0) := x"0000";
signal pin_match   : std_logic;
signal bill_dcd    : std_logic_vector(31 downto 0); --for deposit
signal bill_digit  : std_logic_vector(31 downto 0); --for withdraw
signal sum_d       : std_logic_vector(31 downto 0) := (others => '0'); --sum to deposit
signal sum_w       : std_logic_vector(31 downto 0) := (others => '0'); --sum to withdraw
signal new_sold_d  : std_logic_vector(31 downto 0) := (others => '0'); --new sold d
signal new_sold_w  : std_logic_vector(31 downto 0) := (others => '0'); --new sold w
signal flag        : std_logic_vector(1 downto 0); --flag for withdrawl problems
signal write_en    : std_logic; 


begin

B1 : MPG port map (load, clk, load_en);
B2 : MPG port map (confirm, clk, confirm_en);
B3 : MPG port map (add, clk, add_en);
B4 : MPG port map (confirm_pin, clk, confirm_pin_en);

D: SSD port map (clk, display, an, cat);

R: card_ram
        port map (
            clk      => clk,
            we       => write_en,
            addr     => card_nr,
            data_in  => ram_in,
            data_out => ram_out
        );

 
process(clk)
begin
    if rising_edge(clk) then
        if confirm_pin_en = '1' then
                pin_confirm <= pin;
        end if;
    end if;
end process;

process(clk)
begin
    if rising_edge(clk) then
            if confirm_pin_en = '1' then
                pin_display <= x"000F";
                pin <= x"0000";
            else if load_en = '1' then
                    pin <= pin(11 downto 0) & sw;
                    pin_display <= pin(11 downto 0) & sw;
                end if;   
            end if;
        end if;
end process;

--to enable writing in the ram when the pin is correct and the operation is NOT view sold
process(sel_op, pin_match, confirm_en)
begin
    if sel_op /= "00" and pin_match = '1' then
        write_en <= confirm_en;
    else 
        write_en <= '0';
    end if;
end process;


--verify if the pin is the same as the one stored in the ram, even when the card is changed mid op
process(pin_confirm, ram_out) --pin_confirm
begin
    if pin_confirm = ram_out(31 downto 16) then
        pin_match <= '1';
    else
        pin_match <= '0';
    end if;
end process;

--light up led if pin is correct
led <= pin_match;

--to decide whatever gets displayed
process(pin_match, sel_op, ram_out, new_pin, sum_w, flag, new_sold_d)
begin
    if pin_match = '1' then
        case sel_op is
            when "00" => display <= ram_out(15 downto 0); --sold
            when "01" => display <= new_pin; --you guessed it, its the new pin
            when "10" => display <= sum_d(15 downto 0); --deposit
            when "11" =>  case flag is --now in case of a withdrawl we need to watch out for the red flags 
                            when "00" => display <=sum_w(15 downto 0); --all good
                            when "01" => display <=x"000e"; --insufficient funds
                            when "10" => display <=x"0001"; --error, amount over 1000
                            when "11" => display <=x"000e"; --error, amount over 1000 
                            when others => display <= x"000e";
                          end case;            
            when others => display <= x"000e"; --error, something went wrong
        end case;
    else
        display <= pin_display; --to display whilst the pin is still in the process of making or when it is not correct
    end if;
end process;

--new pin input
process(clk) 
begin
    if rising_edge(clk) then
        if sel_op = "01" then
            if confirm_pin_en = '1' then
                new_pin <= x"0000";
            elsif load_en = '1' then
                new_pin <= new_pin(11 downto 0) & sw;
            end if;
         else 
            new_pin <= x"0000";
        end if;
    end if;
end process;

--to see whatever gets to be stored in ram
process(sel_op, ram_in, ram_out, new_pin, new_sold_d, new_sold_w)
begin
    case sel_op is 
        when "00" => ram_in <= ram_in; --nothing new
        when "01" => ram_in <= new_pin & ram_out(15 downto 0); --the pin gets overwritten by the new one, the sold remains untouched
        when "10" => ram_in <= ram_out(31 downto 16) & new_sold_d(15 downto 0); --bye bye sold(a deposit is made)
        when "11" => ram_in <= ram_out(31 downto 16) & new_sold_w(15 downto 0); --withdraw
        when others => ram_in <= ram_in;
    end case;
end process;


flag(0) <= '1' when (sum_w(15 downto 0) > 1000) else '0'; --flags to remember each error: amount to be withdrawn over 1000? 
flag(1) <= '1' when (sum_w(15 downto 0) > ram_out(15 downto 0)) else '0'; -- or amount to be withdrawn too large 

new_sold_d(15 downto 0) <= sum_d(15 downto 0) + ram_out(15 downto 0);

new_sold_w(15 downto 0) <= ram_out(15 downto 0) - sum_w(15 downto 0) when (flag = "00") else --only withdraw in case of no errors
                           ram_out(15 downto 0);

--deposit cash
process(clk)
begin
if rising_edge(clk) then 
     if sel_op = "10" then
         bill_dcd <= (others => '0'); 
         case bill is
             when "000" => bill_dcd(8 downto 0) <= "000000101"; --5/5
             when "001" => bill_dcd(8 downto 0) <= "000001010"; --10/A
             when "010" => bill_dcd(8 downto 0) <= "000010100"; --20/14
             when "011" => bill_dcd(8 downto 0) <= "000110010"; --50/32
             when "100" => bill_dcd(8 downto 0) <= "001100100"; --100/64
             when "101" => bill_dcd(8 downto 0) <= "011001000"; --200/C8
             when "110" => bill_dcd(8 downto 0) <= "111110100"; --500/1F4 
             when others => bill_dcd(8 downto 0) <="000000000"; --invalid
         end case;
         if add_en = '1' then
              sum_d <= sum_d + bill_dcd; --add the bills
         else if confirm_en = '1' then
              sum_d <= x"00000000"; --dispaly 0 after sum is added to initial sold
              end if;
          end if;
       else
        sum_d <= x"00000000";
        bill_dcd(8 downto 0) <="000000000";
    end if; 
end if;  
end process;

--withdraw cash
process(clk)
begin
    if rising_edge(clk) then 
        if sel_op = "11" then
            if add_en = '1' then
                case bill is
                    when "001" => sum_w(3 downto 0) <= sum_w(3 downto 0) + 1;   --maximum value to withdraw is 1000
                    when "010" => sum_w(7 downto 4) <= sum_w(7 downto 4) + 1;   --meaning 3e8 in hex thus, the sum
                    when "100" => sum_w(11 downto 8) <= sum_w(11 downto 8) + 1; --has maximum 3 digits
                    when others => sum_w <= sum_w;
                end case;
             else if confirm_en = '1' then
                sum_w <= x"00000000"; --same logic from deposit
                  end if;
             end if;
           else 
                sum_w <= x"00000000";
           end if;
    end if;
end process;

end Behavioral;
