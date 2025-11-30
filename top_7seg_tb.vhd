LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.test_helpers.ALL;

ENTITY top_7seg_tb IS
END top_7seg_tb;

ARCHITECTURE Behavioral OF top_7seg_tb IS

    CONSTANT TB_DIVISOR : INTEGER := 20;

    COMPONENT top_7seg IS
        GENERIC (
            CLK_DIVISOR : INTEGER := 50000000
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL an : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL done : BOOLEAN := FALSE; -- Clean exit utility

    CONSTANT clk_period : TIME := 10 ns;
    CONSTANT digit_period : TIME := clk_period * (TB_DIVISOR * 2);

    TYPE seg_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT expected_patterns : seg_array := (
        0 => "1000000", 1 => "1111001", 2 => "0100100", 3 => "0110000",
        4 => "0011001", 5 => "0010010", 6 => "0000010", 7 => "1111000",
        8 => "0000000", 9 => "0010000"
    );

BEGIN

    uut : top_7seg
    GENERIC MAP(
        CLK_DIVISOR => TB_DIVISOR
    )
    PORT MAP(
        clk => clk,
        rst => rst,
        seg => seg,
        an => an
    );

    clk_process : PROCESS
    BEGIN
        WHILE NOT done LOOP
            clk <= '0';
            WAIT FOR clk_period / 2;
            clk <= '1';
            WAIT FOR clk_period / 2;
        END LOOP;
        WAIT; -- suspend forever
    END PROCESS;

    stim_proc : PROCESS
    BEGIN
        rst <= '1';
        WAIT FOR clk_period * 5;
        rst <= '0';

        WAIT FOR clk_period * 2;

        REPORT "Testing digit counting with fast clock divisor...";

        -- First, digit must be 0
        ASSERT seg = expected_patterns(0)
        REPORT "ERROR: Digit 0 - Expected: " & to_string(expected_patterns(0)) &
            ", Got: " & to_string(seg)
            SEVERITY error;

        ASSERT an = "1110"
        REPORT "ERROR: Anode should be 1110 for digit 0"
            SEVERITY error;

        REPORT "Digit " & INTEGER'image(0) & " PASSED - pattern: " & to_string(seg);

        -- Now check digits 1..9, each after one full digit period
        FOR i IN 1 TO 9 LOOP
            WAIT FOR digit_period; -- wait for next slow-clock rising edge

            ASSERT seg = expected_patterns(i)
            REPORT "ERROR: Digit " & INTEGER'image(i) &
                " - Expected: " & to_string(expected_patterns(i)) &
                ", Got: " & to_string(seg)
                SEVERITY error;

            ASSERT an = "1110"
            REPORT "ERROR: Anode should be 1110"
                SEVERITY error;

            REPORT "Digit " & INTEGER'image(i) & " PASSED - pattern: " & to_string(seg);
        END LOOP;

        -- Check wrap-around back to 0 after another digit period
        WAIT FOR digit_period;
        ASSERT seg = expected_patterns(0)
        REPORT "ERROR: Counter did not wrap to 0"
            SEVERITY error;

        REPORT "*** ALL TESTS PASSED ***" SEVERITY note;
        done <= TRUE;
        WAIT;
    END PROCESS;

END Behavioral;