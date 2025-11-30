LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY SevenSegController IS
    PORT (
        digit : IN INTEGER RANGE 0 TO 9; -- digit to display
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- cathode pattern
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- anode control
    );
END SevenSegController;

ARCHITECTURE Behavioral OF SevenSegController IS
    SIGNAL seg_pattern : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN

    PROCESS (digit)
    BEGIN
        CASE digit IS
            WHEN 0 => seg_pattern <= "1000000"; -- 0
            WHEN 1 => seg_pattern <= "1111001"; -- 1
            WHEN 2 => seg_pattern <= "0100100"; -- 2
            WHEN 3 => seg_pattern <= "0110000"; -- 3
            WHEN 4 => seg_pattern <= "0011001"; -- 4
            WHEN 5 => seg_pattern <= "0010010"; -- 5
            WHEN 6 => seg_pattern <= "0000010"; -- 6
            WHEN 7 => seg_pattern <= "1111000"; -- 7
            WHEN 8 => seg_pattern <= "0000000"; -- 8
            WHEN 9 => seg_pattern <= "0010000"; -- 9
            WHEN OTHERS => seg_pattern <= "1111111";
        END CASE;
    END PROCESS;

    seg <= seg_pattern;
    an <= "1110";

END Behavioral;