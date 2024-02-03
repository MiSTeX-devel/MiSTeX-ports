library IEEE;
use IEEE.std_logic_1164.all;
package eprom_defs_pack is
        subtype eprom_rom_entry is std_logic_vector(7 downto 0);
        type eprom_rom_array is array(0 to 16383) of eprom_rom_entry;
        constant eprom_dont_care : eprom_rom_entry := (others=>'-');
        function eprom_entry(data:natural) return eprom_rom_entry;
end package;

library IEEE;
use IEEE.numeric_std.all;
package body eprom_defs_pack is
        function eprom_entry(data:natural) return eprom_rom_entry is
        begin
                return std_logic_vector(to_unsigned(data,eprom_rom_entry'length));
        end eprom_entry;
end package body;