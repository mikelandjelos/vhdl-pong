LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE work.test_helpers.ALL;

ENTITY tb_7seg IS
    -- Testbench has no ports
END tb_7seg;

ARCHITECTURE Behavioral OF tb_7seg IS

    -- Component declaration
    COMPONENT SevenSegController IS
        PORT (
            digit : IN INTEGER RANGE 0 TO 9;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    -- Test signals
    SIGNAL digit : INTEGER RANGE 0 TO 9 := 0;
    SIGNAL seg : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL an : STD_LOGIC_VECTOR(3 DOWNTO 0);

    -- Expected segment patterns
    TYPE seg_array IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(6 DOWNTO 0);
    CONSTANT expected_patterns : seg_array := (
        0 => "1000000", -- 0
        1 => "1111001", -- 1
        2 => "0100100", -- 2
        3 => "0110000", -- 3
        4 => "0011001", -- 4
        5 => "0010010", -- 5
        6 => "0000010", -- 6
        7 => "1111000", -- 7
        8 => "0000000", -- 8
        9 => "0010000" -- 9
    );

BEGIN

    uut : SevenSegController
    PORT MAP(
        digit => digit,
        seg => seg,
        an => an
    );

    -- Stimulus process (no clock needed due to combinational nature of the circuit)
    stim_proc : PROCESS
    BEGIN
        REPORT "Testing SevenSegController (pure combinational logic)...";

        -- Test all digits 0-9
        FOR i IN 0 TO 9 LOOP
            digit <= i;
            WAIT FOR 10 ns; -- Small delay for signal propagation

            -- Check segment pattern
            ASSERT seg = expected_patterns(i)
            REPORT "ERROR: Digit " & INTEGER'image(i) &
                " has wrong pattern. Expected: " &
                to_string(expected_patterns(i)) &
                " Got: " & to_string(seg)
                SEVERITY error;

            -- Check anode
            ASSERT an = "1110"
            REPORT "ERROR: Anode should be 1110, got: " & to_string(an)
                SEVERITY error;

            REPORT "Digit " & INTEGER'image(i) & " PASSED - pattern: " & to_string(seg);
        END LOOP;

        REPORT "*** ALL TESTS PASSED! ***" SEVERITY note;
        WAIT;
    END PROCESS;

END Behavioral;