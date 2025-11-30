LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Drives 4 seven-seg digits (AN3..AN0) using multiplexing.
-- Mapping used here:
--   AN0 -> Player 1 units (rightmost)
--   AN1 -> Player 1 tens
--   AN2 -> Player 2 units
--   AN3 -> Player 2 tens (leftmost)
-- Assumes common-anode active-low an signals.

ENTITY score_7seg IS
    PORT (
        clk : IN STD_LOGIC; -- refresh clock (kHz range)
        rst : IN STD_LOGIC;
        p1_score : IN INTEGER RANGE 0 TO 99; -- player 1 score
        p2_score : IN INTEGER RANGE 0 TO 99; -- player 2 score
        seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0); -- cathode segments
        an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) -- anode selects (active low)
    );
END score_7seg;

ARCHITECTURE Behavioral OF score_7seg IS

    COMPONENT SevenSegController IS
        PORT (
            digit : IN INTEGER RANGE 0 TO 9;
            seg : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            an : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    -- Current digits (derived from scores)
    SIGNAL d_p1_units : INTEGER RANGE 0 TO 9;
    SIGNAL d_p1_tens : INTEGER RANGE 0 TO 9;
    SIGNAL d_p2_units : INTEGER RANGE 0 TO 9;
    SIGNAL d_p2_tens : INTEGER RANGE 0 TO 9;

    -- Segment patterns for each digit
    SIGNAL seg_p1_units : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL seg_p1_tens : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL seg_p2_units : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL seg_p2_tens : STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Simple 2-bit scan counter
    SIGNAL scan_sel : UNSIGNED(1 DOWNTO 0) := (OTHERS => '0');

BEGIN

    -- Derive digits from scores
    digit_split : PROCESS (p1_score, p2_score)
    BEGIN
        d_p1_units <= p1_score MOD 10;
        d_p1_tens <= (p1_score / 10) MOD 10;
        d_p2_units <= p2_score MOD 10;
        d_p2_tens <= (p2_score / 10) MOD 10;
    END PROCESS;

    -- Instantiate one mapper per digit; ignore their 'an' output
    map_p1_units : SevenSegController PORT MAP(digit => d_p1_units, seg => seg_p1_units, an => OPEN);
    map_p1_tens : SevenSegController PORT MAP(digit => d_p1_tens, seg => seg_p1_tens, an => OPEN);
    map_p2_units : SevenSegController PORT MAP(digit => d_p2_units, seg => seg_p2_units, an => OPEN);
    map_p2_tens : SevenSegController PORT MAP(digit => d_p2_tens, seg => seg_p2_tens, an => OPEN);

    -- Scan selector: advance on each clk edge
    scan_proc : PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            scan_sel <= (OTHERS => '0');
        ELSIF rising_edge(clk) THEN
            scan_sel <= scan_sel + 1;
        END IF;
    END PROCESS;

    -- Multiplex segments according to active digit
    WITH scan_sel SELECT
        seg <= seg_p1_units WHEN "00",
        seg_p1_tens WHEN "01",
        seg_p2_units WHEN "10",
        seg_p2_tens WHEN "11",
        (OTHERS => '1') WHEN OTHERS;

    -- Drive anodes (active low)
    WITH scan_sel SELECT
        an <= "1110" WHEN "00", -- AN0 active (P1 units)
        "1101" WHEN "01", -- AN1 active (P1 tens)
        "1011" WHEN "10", -- AN2 active (P2 units)
        "0111" WHEN "11", -- AN3 active (P2 tens)
        "1111" WHEN OTHERS;

END Behavioral;