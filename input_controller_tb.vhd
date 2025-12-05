LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.test_helpers.ALL;

ENTITY input_controller_tb IS
END input_controller_tb;

ARCHITECTURE Behavioral OF input_controller_tb IS

    COMPONENT input_controller IS
        GENERIC (
            MAX_POS        : INTEGER := 420;
            INIT_POS       : INTEGER := 10;
            STEP           : INTEGER := 3;
            SAMPLE_DIVISOR : INTEGER := 8
        );
        PORT (
            clk         : IN  STD_LOGIC;
            rst         : IN  STD_LOGIC;
            btn_up      : IN  STD_LOGIC;
            btn_down    : IN  STD_LOGIC;
            paddle_pos  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk        : STD_LOGIC := '0';
    SIGNAL rst        : STD_LOGIC := '0';
    SIGNAL btn_up     : STD_LOGIC := '0';
    SIGNAL btn_down   : STD_LOGIC := '0';
    SIGNAL paddle_pos : STD_LOGIC_VECTOR(31 DOWNTO 0);

    SIGNAL done : BOOLEAN := FALSE;

    CONSTANT clk_period : TIME := 10 ns; -- 100 MHz
    CONSTANT sample_div : INTEGER := 8;  -- must match generic above
    CONSTANT sample_period : TIME := clk_period * sample_div;

    -- convenience function to read current pos as integer
    FUNCTION pos_i RETURN INTEGER IS
    BEGIN
        RETURN to_integer(unsigned(paddle_pos(15 DOWNTO 0)));
    END FUNCTION;

BEGIN

    uut : input_controller
        GENERIC MAP (
            MAX_POS => 30,
            INIT_POS => 10,
            STEP => 3,
            SAMPLE_DIVISOR => sample_div
        )
        PORT MAP (
            clk => clk,
            rst => rst,
            btn_up => btn_up,
            btn_down => btn_down,
            paddle_pos => paddle_pos
        );

    clk_proc : PROCESS
    BEGIN
        WHILE NOT done LOOP
            clk <= '0'; WAIT FOR clk_period/2;
            clk <= '1'; WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim : PROCESS
        VARIABLE p0, p1 : INTEGER;
    BEGIN
        REPORT "Testing input_controller sampling and bounds...";
        rst <= '1'; WAIT FOR clk_period * 5; rst <= '0';

        -- after reset
        WAIT FOR sample_period + clk_period; -- wait past first sample
        p0 := pos_i;
        ASSERT p0 = 10
        REPORT "After reset expected 10, got " & INTEGER'image(p0)
        SEVERITY error;

        -- hold UP for 3 samples => +3*3 = +9
        btn_up <= '1';
        FOR i IN 1 TO 3 LOOP
            WAIT FOR sample_period;
        END LOOP;
        btn_up <= '0'; WAIT FOR clk_period;
        p1 := pos_i;
        ASSERT p1 = 19
        REPORT "Hold UP 3 samples expected 19, got " & INTEGER'image(p1)
        SEVERITY error;

        -- simultaneous up+down: no movement over 2 samples
        btn_up <= '1'; btn_down <= '1';
        WAIT FOR sample_period * 2;
        btn_up <= '0'; btn_down <= '0'; WAIT FOR clk_period;
        ASSERT pos_i = 19
        REPORT "UP+DOWN should not move, got " & INTEGER'image(pos_i)
        SEVERITY error;

        -- press DOWN for 5 samples => -5*3 = -15 -> clamp at 0 relative to 19 -> 4
        btn_down <= '1';
        FOR i IN 1 TO 5 LOOP
            WAIT FOR sample_period;
        END LOOP;
        btn_down <= '0'; WAIT FOR clk_period;
        ASSERT pos_i = 4
        REPORT "DOWN 5 samples expected 4, got " & INTEGER'image(pos_i)
        SEVERITY error;

        -- drive below 0: 2 more DOWN samples -> should clamp at 0
        btn_down <= '1'; WAIT FOR sample_period * 2; btn_down <= '0'; WAIT FOR clk_period;
        ASSERT pos_i = 0
        REPORT "Clamp at 0 failed, got " & INTEGER'image(pos_i)
        SEVERITY error;

        -- drive to top (MAX_POS=30): need ceil((30-0)/3)=10 samples up
        btn_up <= '1'; FOR i IN 1 TO 12 LOOP WAIT FOR sample_period; END LOOP; btn_up <= '0'; WAIT FOR clk_period;
        ASSERT pos_i = 30
        REPORT "Clamp at MAX_POS failed, got " & INTEGER'image(pos_i)
        SEVERITY error;

        REPORT "*** input_controller_tb: ALL CHECKS PASSED ***" SEVERITY note;
        done <= TRUE; WAIT;
    END PROCESS;

END Behavioral;

