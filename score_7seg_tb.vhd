LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.test_helpers.ALL;

ENTITY score_7seg_tb IS
END score_7seg_tb;

ARCHITECTURE Behavioral OF score_7seg_tb IS

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

    SIGNAL clk : STD_LOGIC := '0';
    SIGNAL rst : STD_LOGIC := '0';
    SIGNAL p1_score : INTEGER RANGE 0 TO 99 := 0;
    SIGNAL p2_score : INTEGER RANGE 0 TO 99 := 0;
    SIGNAL seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL an : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL p1_unit : INTEGER;
    SIGNAL p1_tens : INTEGER;
    SIGNAL p2_unit : INTEGER;
    SIGNAL p2_tens : INTEGER;

    SIGNAL done : BOOLEAN := FALSE; -- Clean exit utility

    CONSTANT clk_period : TIME := 10 ns;

    TYPE seg_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT expected_patterns : seg_array := (
        0 => "1000000", 1 => "1111001", 2 => "0100100", 3 => "0110000",
        4 => "0011001", 5 => "0010010", 6 => "0000010", 7 => "1111000",
        8 => "0000000", 9 => "0010000"
    );

BEGIN

    UUT : score_7seg
    PORT MAP(
        clk => clk,
        rst => rst,
        p1_score => p1_score,
        p2_score => p2_score,
        seg => seg,
        an => an
    );

    clk_process : PROCESS
    BEGIN
        WHILE NOT done LOOP
            clk <= '0';
            WAIT FOR clk_period/2;
            clk <= '1';
            WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim_proc : PROCESS
    BEGIN
        REPORT "Testing score_7seg multiplexing...";
        rst <= '1';
        WAIT FOR clk_period * 4;
        rst <= '0';

        -- Set known scores and verify per-digit scan
        p1_score <= 52; -- tens=5, units=2
        p2_score <= 37; -- tens=3, units=7
        WAIT FOR clk_period; -- allow signals to propagate

        -- We expect scan order over consecutive refresh ticks:
        -- an="1110" -> P1 units (2)
        -- an="1101" -> P1 tens  (5)
        -- an="1011" -> P2 units (7)
        -- an="0111" -> P2 tens  (3)

        p1_unit <= p1_score MOD 10;
        p1_tens <= (p1_score / 10) MOD 10;
        p2_unit <= p2_score MOD 10;
        p2_tens <= (p2_score / 10) MOD 10;

        -- Step 0: expect P1 units (2)
        WAIT UNTIL an = "1110";
        WAIT FOR 1 ns;
        ASSERT seg = expected_patterns(p1_unit)
        REPORT "Wrong seg for P1 units=" & INTEGER'image(p1_unit) & ". Got: " & to_string(seg)
            SEVERITY error;

        REPORT "Units digit for player one PASSED - " & "digit=" & INTEGER'image(p1_unit) & " pattern='" & to_string(seg) & "'";

        -- Step 1: expect P1 tens (5)
        WAIT UNTIL an = "1101";
        WAIT FOR 1 ns;
        ASSERT seg = expected_patterns(p1_tens)
        REPORT "Wrong seg for P1 tens=" & INTEGER'image(p1_tens) & ". Got: " & to_string(seg)
            SEVERITY error;

        REPORT "Tens digit for player one PASSED - " & "digit=" & INTEGER'image(p1_tens) & " pattern='" & to_string(seg) & "'";

        -- Step 2: expect P2 units (7)
        WAIT UNTIL an = "1011";
        WAIT FOR 1 ns;
        ASSERT seg = expected_patterns(p2_unit)
        REPORT "Wrong seg for P2 units=" & INTEGER'image(p2_unit) & ". Got: " & to_string(seg)
            SEVERITY error;

        REPORT "Units digit for player two PASSED - " & "digit=" & INTEGER'image(p2_unit) & " pattern='" & to_string(seg) & "'";

        -- Step 3: expect P2 tens (3)
        WAIT UNTIL an = "0111";
        WAIT FOR 1 ns;
        ASSERT seg = expected_patterns(p2_tens)
        REPORT "Wrong seg for P2 tens=" & INTEGER'image(p2_tens) & ". Got: " & to_string(seg)
            SEVERITY error;

        REPORT "Tens digit for player two PASSED - " & "digit=" & INTEGER'image(p2_tens) & " pattern='" & to_string(seg) & "'";

        REPORT "*** score_7seg_tb: ALL CHECKS PASSED ***" SEVERITY note;
        done <= TRUE;
        WAIT;
    END PROCESS;

END Behavioral;