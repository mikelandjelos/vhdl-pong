LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY top_score7seg IS
    GENERIC (
        REFRESH_DIVISOR : INTEGER := 50000; -- drives ~1 kHz refresh if clk=100MHz
        SCORE_DIVISOR : INTEGER := 50000000 -- drives ~1 Hz score tick if clk=100MHz
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END top_score7seg;

ARCHITECTURE Behavioral OF top_score7seg IS

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

    COMPONENT score_7seg IS
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            p1_score : IN INTEGER RANGE 0 TO 99;
            p2_score : IN INTEGER RANGE 0 TO 99;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk_refresh : STD_LOGIC;
    SIGNAL clk_score : STD_LOGIC;

    SIGNAL p1_score : INTEGER RANGE 0 TO 99 := 0;
    SIGNAL p2_score : INTEGER RANGE 0 TO 99 := 0;

BEGIN

    -- Generate refresh clock for digit multiplexing
    u_div_refresh : clk_div
    GENERIC MAP(DIVISOR => REFRESH_DIVISOR)
    PORT MAP(
        clk_in => clk,
        rst => rst,
        clk_out => clk_refresh
    );

    -- Generate slow clock to emulate score changes
    u_div_score : clk_div
    GENERIC MAP(DIVISOR => SCORE_DIVISOR)
    PORT MAP(
        clk_in => clk,
        rst => rst,
        clk_out => clk_score
    );

    -- Simple score update for simulation/bring-up
    score_counter : PROCESS (clk_score, rst)
    BEGIN
        IF rst = '1' THEN
            p1_score <= 0;
            p2_score <= 0;
        ELSIF rising_edge(clk_score) THEN
            IF p1_score = 99 THEN
                p1_score <= 0;
            ELSE
                p1_score <= p1_score + 1;
            END IF;

            IF p2_score = 99 THEN
                p2_score <= 0;
            ELSE
                p2_score <= p2_score + 1;
            END IF;
        END IF;
    END PROCESS;

    -- Drive the 7-seg scoreboard
    u_score : score_7seg
    PORT MAP(
        clk => clk_refresh,
        rst => rst,
        p1_score => p1_score,
        p2_score => p2_score,
        seg => seg,
        an => an
    );

END Behavioral;