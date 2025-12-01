LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- VGA 640x480@60Hz controller (25 MHz pixel clock)
-- Inputs: ball and paddle positions (top-left Y for paddles; top-left X/Y for ball)
-- Outputs: HSYNC, VSYNC (active low), and 3-bit RGB

ENTITY vga_controller IS
    PORT (
        clk : IN STD_LOGIC; -- 25 MHz pixel clock
        reset : IN STD_LOGIC;

        ball_x : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        ball_y : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        paddle1_pos : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- vertical position
        paddle2_pos : IN STD_LOGIC_VECTOR(31 DOWNTO 0); -- vertical position

        hsync : OUT STD_LOGIC;
        vsync : OUT STD_LOGIC;
        rgb : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END vga_controller;

ARCHITECTURE Behavioral OF vga_controller IS
    -- VGA timing constants for 640x480@60
    CONSTANT h_pixels : INTEGER := 800; -- total per line
    CONSTANT v_lines : INTEGER := 525; -- total per frame
    CONSTANT h_pulse : INTEGER := 96; -- HSYNC pulse width
    CONSTANT h_bp : INTEGER := 48; -- back porch
    CONSTANT h_fp : INTEGER := 16; -- front porch
    CONSTANT v_pulse : INTEGER := 2; -- VSYNC pulse width
    CONSTANT v_bp : INTEGER := 33; -- back porch
    CONSTANT v_fp : INTEGER := 10; -- front porch

    -- visible area
    CONSTANT vis_w : INTEGER := 640;
    CONSTANT vis_h : INTEGER := 480;

    -- counters
    SIGNAL h_count : INTEGER RANGE 0 TO h_pixels - 1 := 0;
    SIGNAL v_count : INTEGER RANGE 0 TO v_lines - 1 := 0;
    SIGNAL h_sync : STD_LOGIC := '1';
    SIGNAL v_sync : STD_LOGIC := '1';

    -- current pixel coordinates within visible area
    SIGNAL pixel_x : INTEGER := 0;
    SIGNAL pixel_y : INTEGER := 0;

    -- geometry
    CONSTANT PADDLE_W : INTEGER := 8;
    CONSTANT PADDLE_H : INTEGER := 60;
    CONSTANT BALL_SIZE : INTEGER := 8;
    CONSTANT P1_X : INTEGER := 16; -- left paddle X
    CONSTANT P2_X : INTEGER := vis_w - 16 - PADDLE_W; -- right paddle X

    -- decoded positions
    SIGNAL s_ball_x : INTEGER := 0;
    SIGNAL s_ball_y : INTEGER := 0;
    SIGNAL s_paddle1_pos : INTEGER := 0; -- Y
    SIGNAL s_paddle2_pos : INTEGER := 0; -- Y

BEGIN

    -- timing and sync generation
    PROCESS (clk, reset)
    BEGIN
        IF reset = '1' THEN
            h_count <= 0;
            v_count <= 0;
            h_sync <= '1';
            v_sync <= '1';
            pixel_x <= 0;
            pixel_y <= 0;
        ELSIF rising_edge(clk) THEN
            IF h_count = h_pixels - 1 THEN
                h_count <= 0;
                IF v_count = v_lines - 1 THEN
                    v_count <= 0;
                ELSE
                    v_count <= v_count + 1;
                END IF;
            ELSE
                h_count <= h_count + 1;
            END IF;

            -- HSYNC active low during pulse
            IF h_count < h_pulse THEN
                h_sync <= '0';
            ELSE
                h_sync <= '1';
            END IF;

            -- VSYNC active low during pulse
            IF v_count < v_pulse THEN
                v_sync <= '0';
            ELSE
                v_sync <= '1';
            END IF;

            -- visible pixel coordinates (can be negative outside visible area)
            pixel_x <= h_count - (h_pulse + h_bp);
            pixel_y <= v_count - (v_pulse + v_bp);
        END IF;
    END PROCESS;

    -- decode position inputs to integers and clamp
    PROCESS (ball_x, ball_y, paddle1_pos, paddle2_pos)
        VARIABLE bx, by, p1y, p2y : INTEGER;
    BEGIN
        bx := to_integer(unsigned(ball_x(9 DOWNTO 0))); -- limit to 0..1023 then clamp
        by := to_integer(unsigned(ball_y(9 DOWNTO 0)));
        p1y := to_integer(unsigned(paddle1_pos(9 DOWNTO 0)));
        p2y := to_integer(unsigned(paddle2_pos(9 DOWNTO 0)));

        -- clamp into visible area
        IF bx < 0 THEN
            bx := 0;
        END IF;
        IF bx > vis_w - BALL_SIZE THEN
            bx := vis_w - BALL_SIZE;
        END IF;
        IF by < 0 THEN
            by := 0;
        END IF;
        IF by > vis_h - BALL_SIZE THEN
            by := vis_h - BALL_SIZE;
        END IF;

        IF p1y < 0 THEN
            p1y := 0;
        END IF;
        IF p1y > vis_h - PADDLE_H THEN
            p1y := vis_h - PADDLE_H;
        END IF;
        IF p2y < 0 THEN
            p2y := 0;
        END IF;
        IF p2y > vis_h - PADDLE_H THEN
            p2y := vis_h - PADDLE_H;
        END IF;

        s_ball_x <= bx;
        s_ball_y <= by;
        s_paddle1_pos <= p1y;
        s_paddle2_pos <= p2y;
    END PROCESS;

    -- pixel generator: inside visible area only
    PROCESS (pixel_x, pixel_y, s_ball_x, s_ball_y, s_paddle1_pos, s_paddle2_pos)
        VARIABLE in_visible : BOOLEAN;
        VARIABLE x, y : INTEGER;
    BEGIN
        x := pixel_x;
        y := pixel_y;
        in_visible := (x >= 0) AND (x < vis_w) AND (y >= 0) AND (y < vis_h);

        IF in_visible THEN
            -- shapes
            -- left paddle: green "010"
            IF (x >= P1_X) AND (x < P1_X + PADDLE_W) AND (y >= s_paddle1_pos) AND (y < s_paddle1_pos + PADDLE_H) THEN
                rgb <= "010";
                -- right paddle: green
            ELSIF (x >= P2_X) AND (x < P2_X + PADDLE_W) AND (y >= s_paddle2_pos) AND (y < s_paddle2_pos + PADDLE_H) THEN
                rgb <= "010";
                -- ball: white "111"
            ELSIF (x >= s_ball_x) AND (x < s_ball_x + BALL_SIZE) AND (y >= s_ball_y) AND (y < s_ball_y + BALL_SIZE) THEN
                rgb <= "111";
            ELSE
                rgb <= "000"; -- background black
            END IF;
        ELSE
            rgb <= "000"; -- outside visible area
        END IF;
    END PROCESS;

    hsync <= h_sync;
    vsync <= v_sync;

END Behavioral;