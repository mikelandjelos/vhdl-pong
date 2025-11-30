LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY top_7seg IS
    GENERIC (
        CLK_DIVISOR : INTEGER := 50000000
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END top_7seg;

ARCHITECTURE Behavioral OF top_7seg IS

    COMPONENT clk_div IS
        GENERIC (
            DIVISOR : INTEGER := 50000000
        );
        PORT (
            clk_in : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            clk_out : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT SevenSegController IS
        PORT (
            digit : IN INTEGER RANGE 0 TO 9;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk_slow : STD_LOGIC;
    SIGNAL digit_counter : INTEGER RANGE 0 TO 9 := 0;

BEGIN

    clk_divider : clk_div
    GENERIC MAP(
        DIVISOR => CLK_DIVISOR
    )
    PORT MAP(
        clk_in => clk,
        rst => rst,
        clk_out => clk_slow
    );

    counter_proc : PROCESS (clk_slow, rst)
    BEGIN
        IF rst = '1' THEN
            digit_counter <= 0;
        ELSIF rising_edge(clk_slow) THEN
            IF digit_counter = 9 THEN
                digit_counter <= 0;
            ELSE
                digit_counter <= digit_counter + 1;
            END IF;
        END IF;
    END PROCESS;

    seven_seg : SevenSegController
    PORT MAP(
        digit => digit_counter,
        seg => seg,
        an => an
    );

END Behavioral;