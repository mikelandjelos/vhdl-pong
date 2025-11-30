LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY clk_div IS
    GENERIC (
        DIVISOR : INTEGER := 50000000
    );
    PORT (
        clk_in : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        clk_out : OUT STD_LOGIC
    );
END clk_div;

ARCHITECTURE Behavioral OF clk_div IS
    SIGNAL counter : INTEGER := 0;
    SIGNAL clk_div_signal : STD_LOGIC := '0';
BEGIN

    PROCESS (clk_in, rst)
    BEGIN
        IF rst = '1' THEN
            counter <= 0;
            clk_div_signal <= '0';
        ELSIF rising_edge(clk_in) THEN
            IF counter = DIVISOR - 1 THEN
                counter <= 0;
                clk_div_signal <= NOT clk_div_signal;
            ELSE
                counter <= counter + 1;
            END IF;
        END IF;
    END PROCESS;

    clk_out <= clk_div_signal;

END Behavioral;