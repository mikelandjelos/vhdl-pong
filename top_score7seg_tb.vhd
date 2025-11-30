LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE work.test_helpers.ALL;

ENTITY top_score7seg_tb IS
END top_score7seg_tb;

ARCHITECTURE Behavioral OF top_score7seg_tb IS

    COMPONENT top_score7seg IS
        GENERIC (
            REFRESH_DIVISOR : INTEGER := 50000;
            SCORE_DIVISOR : INTEGER := 50000000
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

    TYPE seg_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT patterns : seg_array := (
        0 => "1000000", 1 => "1111001", 2 => "0100100", 3 => "0110000",
        4 => "0011001", 5 => "0010010", 6 => "0000010", 7 => "1111000",
        8 => "0000000", 9 => "0010000"
    );

    -- Decode seg pattern to integer digit (returns -1 if not a valid digit)
    FUNCTION pat_to_digit(p : STD_LOGIC_VECTOR(6 DOWNTO 0)) RETURN INTEGER IS
    BEGIN
        FOR d IN 0 TO 9 LOOP
            IF p = patterns(d) THEN
                RETURN d;
            END IF;
        END LOOP;
        RETURN -1;
    END FUNCTION;

    -- Captured digits per position
    SIGNAL d_p1u, d_p1t, d_p2u, d_p2t : INTEGER := - 1;

BEGIN

    UUT : top_score7seg
    GENERIC MAP(
        REFRESH_DIVISOR => 4, -- fast scan for simulation
        SCORE_DIVISOR => 1000 -- slow score tick so initial capture sees 0/0
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
            WAIT FOR clk_period/2;
            clk <= '1';
            WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim_proc : PROCESS
        VARIABLE s_p1u, s_p1t, s_p2u, s_p2t : INTEGER;
        VARIABLE t_p1u, t_p1t, t_p2u, t_p2t : INTEGER;
    BEGIN
        REPORT "Testing top_score7seg integration...";
        rst <= '1';
        WAIT FOR clk_period * 5;
        rst <= '0';

        -- Initial capture: at reset scores are 0/0
        WAIT UNTIL an = "1110";
        WAIT FOR 1 ns;
        s_p1u := pat_to_digit(seg);
        REPORT "Step 0 (AN=1110) P1 units = " & INTEGER'image(s_p1u) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "1101";
        WAIT FOR 1 ns;
        s_p1t := pat_to_digit(seg);
        REPORT "Step 1 (AN=1101) P1 tens  = " & INTEGER'image(s_p1t) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "1011";
        WAIT FOR 1 ns;
        s_p2u := pat_to_digit(seg);
        REPORT "Step 2 (AN=1011) P2 units = " & INTEGER'image(s_p2u) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "0111";
        WAIT FOR 1 ns;
        s_p2t := pat_to_digit(seg);
        REPORT "Step 3 (AN=0111) P2 tens  = " & INTEGER'image(s_p2t) & ", seg=" & to_string(seg);
        REPORT "Initial capture summary -> P1=" & INTEGER'image(s_p1t) & INTEGER'image(s_p1u) &
            " P2=" & INTEGER'image(s_p2t) & INTEGER'image(s_p2u);
        ASSERT s_p1u = 0 AND s_p1t = 0 AND s_p2u = 0 AND s_p2t = 0
        REPORT "Initial digits not 0/0 0/0. Got: P1=" & INTEGER'image(s_p1t) & INTEGER'image(s_p1u) &
            " P2=" & INTEGER'image(s_p2t) & INTEGER'image(s_p2u)
            SEVERITY error;

        -- Wait long enough for at least one score tick
        -- With SCORE_DIVISOR=1000, T ~= 20us per rising edge
        REPORT "Waiting for score tick...";
        WAIT FOR 25 us;

        -- Capture again and verify P1 has advanced, P2 likely still 0
        WAIT UNTIL an = "1110";
        WAIT FOR 1 ns;
        t_p1u := pat_to_digit(seg);
        REPORT "Step 0 (AN=1110) P1 units = " & INTEGER'image(t_p1u) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "1101";
        WAIT FOR 1 ns;
        t_p1t := pat_to_digit(seg);
        REPORT "Step 1 (AN=1101) P1 tens  = " & INTEGER'image(t_p1t) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "1011";
        WAIT FOR 1 ns;
        t_p2u := pat_to_digit(seg);
        REPORT "Step 2 (AN=1011) P2 units = " & INTEGER'image(t_p2u) & ", seg=" & to_string(seg);
        WAIT UNTIL an = "0111";
        WAIT FOR 1 ns;
        t_p2t := pat_to_digit(seg);
        REPORT "Step 3 (AN=0111) P2 tens  = " & INTEGER'image(t_p2t) & ", seg=" & to_string(seg);
        REPORT "Post-tick summary -> P1=" & INTEGER'image(t_p1t) & INTEGER'image(t_p1u) &
            " P2=" & INTEGER'image(t_p2t) & INTEGER'image(t_p2u);

        ASSERT (t_p1u /= s_p1u OR t_p1t /= s_p1t)
        REPORT "P1 digits did not advance as expected"
            SEVERITY error;

        ASSERT t_p2u = 0 AND t_p2t = 0
        REPORT "P2 should still be 0/0 for short run. Got: " &
            INTEGER'image(t_p2t) & INTEGER'image(t_p2u)
            SEVERITY error;

        REPORT "*** top_score7seg_tb: BASIC CHECKS PASSED ***" SEVERITY note;
        done <= TRUE;
        WAIT;
    END PROCESS;

END Behavioral;