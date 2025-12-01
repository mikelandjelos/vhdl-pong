LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;

ENTITY vga_video_tb IS
END vga_video_tb;

ARCHITECTURE tb OF vga_video_tb IS

    COMPONENT vga_controller IS
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            ball_x : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            ball_y : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            paddle1_pos : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            paddle2_pos : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
            hsync : OUT STD_LOGIC;
            vsync : OUT STD_LOGIC;
            rgb : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk25 : STD_LOGIC := '0';
    SIGNAL reset : STD_LOGIC := '0';
    SIGNAL hsync : STD_LOGIC;
    SIGNAL vsync : STD_LOGIC;
    SIGNAL rgb : STD_LOGIC_VECTOR(2 DOWNTO 0);
    SIGNAL ball_x : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL ball_y : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL paddle1_pos : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
    SIGNAL paddle2_pos : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');

    SIGNAL done : BOOLEAN;

    CONSTANT clk_period : TIME := 40 ns; -- 25 MHz

    -- VGA constants (must match DUT)
    CONSTANT h_pixels : INTEGER := 800;
    CONSTANT v_lines : INTEGER := 525;
    CONSTANT h_bp : INTEGER := 48;
    CONSTANT v_bp : INTEGER := 33;
    CONSTANT vis_w : INTEGER := 640;
    CONSTANT vis_h : INTEGER := 480;

    CONSTANT N_FRAMES : INTEGER := 60; -- produce 60 frames (~2 seconds at 30 fps after conversion)

    -- zero-pad integer to width 4
    FUNCTION zpad4(n : INTEGER) RETURN STRING IS
        VARIABLE nn : INTEGER := n;
        VARIABLE res : STRING(1 TO 4) := (OTHERS => '0');
        VARIABLE i : INTEGER := 4;
    BEGIN
        IF nn < 0 THEN
            nn := 0;
        END IF;
        WHILE (i >= 1) AND (nn > 0) LOOP
            res(i) := CHARACTER'val(CHARACTER'pos('0') + (nn MOD 10));
            nn := nn / 10;
            i := i - 1;
        END LOOP;
        RETURN res;
    END FUNCTION;

BEGIN

    dut : vga_controller
    PORT MAP(
        clk => clk25,
        reset => reset,
        ball_x => ball_x,
        ball_y => ball_y,
        paddle1_pos => paddle1_pos,
        paddle2_pos => paddle2_pos,
        hsync => hsync,
        vsync => vsync,
        rgb => rgb
    );

    -- 25 MHz pixel clock
    clk_process : PROCESS
    BEGIN
        WHILE NOT done LOOP
            clk25 <= '0';
            WAIT FOR clk_period/2;
            clk25 <= '1';
            WAIT FOR clk_period/2;
        END LOOP;
        WAIT;
    END PROCESS;

    stim : PROCESS
        FILE ppm : text; -- opened per frame
        VARIABLE L : line;
        VARIABLE r, g, b : INTEGER := 0;
        VARIABLE lines_since_vsync_rise : INTEGER := 0;
        VARIABLE pix_since_hsync_rise : INTEGER := 0;
    BEGIN
        -- Initial positions
        ball_x <= STD_LOGIC_VECTOR(to_unsigned(100, 32));
        ball_y <= STD_LOGIC_VECTOR(to_unsigned(100, 32));
        paddle1_pos <= STD_LOGIC_VECTOR(to_unsigned(150, 32));
        paddle2_pos <= STD_LOGIC_VECTOR(to_unsigned(250, 32));
        reset <= '1';
        WAIT FOR clk_period * 8;
        reset <= '0';

        FOR f IN 0 TO N_FRAMES - 1 LOOP
            -- Open per-frame file (ensure `frames/` exists before running)
            file_open(ppm, "frames/frame_" & zpad4(f) & ".ppm", write_mode);

            -- PPM header
            write(L, STRING'("P3"));
            writeline(ppm, L);
            write(L, STRING'("640 480"));
            writeline(ppm, L);
            write(L, STRING'("255"));
            writeline(ppm, L);

            -- Align to start of visible region of next frame
            WAIT UNTIL rising_edge(vsync);
            lines_since_vsync_rise := 0;

            -- Capture visible 480 lines
            WHILE lines_since_vsync_rise < v_bp + vis_h LOOP
                WAIT UNTIL rising_edge(hsync);
                pix_since_hsync_rise := 0;

                FOR x IN 0 TO h_pixels - 1 LOOP
                    WAIT UNTIL rising_edge(clk25);

                    -- only record visible region
                    IF (lines_since_vsync_rise >= v_bp) AND
                        (pix_since_hsync_rise >= h_bp) AND
                        (pix_since_hsync_rise < h_bp + vis_w) AND
                        (lines_since_vsync_rise < v_bp + vis_h) THEN

                        IF rgb(2) = '1' THEN
                            r := 255;
                        ELSE
                            r := 0;
                        END IF;
                        IF rgb(1) = '1' THEN
                            g := 255;
                        ELSE
                            g := 0;
                        END IF;
                        IF rgb(0) = '1' THEN
                            b := 255;
                        ELSE
                            b := 0;
                        END IF;

                        write(L, r);
                        write(L, ' ');
                        write(L, g);
                        write(L, ' ');
                        write(L, b);
                        write(L, ' ');
                        IF (pix_since_hsync_rise - h_bp) = vis_w - 1 THEN
                            writeline(ppm, L);
                        END IF;
                    END IF;
                    pix_since_hsync_rise := pix_since_hsync_rise + 1;
                END LOOP;

                lines_since_vsync_rise := lines_since_vsync_rise + 1;
            END LOOP;

            file_close(ppm);

            -- simple per-frame animation (wrap within bounds)
            ball_x <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(ball_x(15 DOWNTO 0))) + 6) MOD (640 - 8), 32));
            ball_y <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(ball_y(15 DOWNTO 0))) + 4) MOD (480 - 8), 32));
            paddle1_pos <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(paddle1_pos(15 DOWNTO 0))) + 3) MOD (480 - 60), 32));
            paddle2_pos <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(paddle2_pos(15 DOWNTO 0))) + 2) MOD (480 - 60), 32));
        END LOOP;

        ASSERT false REPORT "Frames written to frames/frame_0000.ppm ..." SEVERITY note;
        done <= TRUE;
        WAIT;
    END PROCESS;

END tb;