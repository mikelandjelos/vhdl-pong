LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Button-driven paddle position controller
-- Samples buttons at a fixed rate and increments/decrements the position.

ENTITY input_controller IS
    GENERIC (
        MAX_POS        : INTEGER := 480 - 60;   -- clamp top (visible height - paddle height)
        INIT_POS       : INTEGER := 200;        -- reset/initial position
        STEP           : INTEGER := 2;          -- position delta per sample
        SAMPLE_DIVISOR : INTEGER := 50000       -- sample enable every N clk cycles (100MHz -> ~2kHz)
    );
    PORT (
        clk         : IN  STD_LOGIC;
        rst         : IN  STD_LOGIC;
        btn_up      : IN  STD_LOGIC;           -- active-high
        btn_down    : IN  STD_LOGIC;           -- active-high
        paddle_pos  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END input_controller;

ARCHITECTURE Behavioral OF input_controller IS
    -- two-stage sync for buttons
    SIGNAL up_meta, up_sync   : STD_LOGIC := '0';
    SIGNAL down_meta, down_sync : STD_LOGIC := '0';

    -- sample enable generator
    SIGNAL cnt      : INTEGER RANGE 0 TO SAMPLE_DIVISOR-1 := 0;
    SIGNAL sample_en : STD_LOGIC := '0';

    -- position register (integer for easy math)
    SIGNAL pos : INTEGER RANGE 0 TO MAX_POS := INIT_POS;
BEGIN

    -- synchronize asynchronous button inputs
    PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            up_meta   <= btn_up;
            up_sync   <= up_meta;
            down_meta <= btn_down;
            down_sync <= down_meta;
        END IF;
    END PROCESS;

    -- sample enable: pulse high for one clk every SAMPLE_DIVISOR cycles
    PROCESS (clk, rst)
    BEGIN
        IF rst = '1' THEN
            cnt <= 0;
            sample_en <= '0';
        ELSIF rising_edge(clk) THEN
            IF cnt = SAMPLE_DIVISOR - 1 THEN
                cnt <= 0;
                sample_en <= '1';
            ELSE
                cnt <= cnt + 1;
                sample_en <= '0';
            END IF;
        END IF;
    END PROCESS;

    -- position update on sample enable
    PROCESS (clk, rst)
        VARIABLE next_pos : INTEGER;
    BEGIN
        IF rst = '1' THEN
            pos <= INIT_POS;
        ELSIF rising_edge(clk) THEN
            IF sample_en = '1' THEN
                next_pos := pos;
                IF (up_sync = '1') AND (down_sync = '0') THEN
                    next_pos := pos + STEP;
                ELSIF (down_sync = '1') AND (up_sync = '0') THEN
                    next_pos := pos - STEP;
                END IF;

                -- clamp
                IF next_pos < 0 THEN
                    next_pos := 0;
                ELSIF next_pos > MAX_POS THEN
                    next_pos := MAX_POS;
                END IF;

                pos <= next_pos;
            END IF;
        END IF;
    END PROCESS;

    paddle_pos <= STD_LOGIC_VECTOR(to_unsigned(pos, 32));

END Behavioral;

