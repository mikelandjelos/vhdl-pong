LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;

ENTITY vga_tb IS
END vga_tb;

ARCHITECTURE tb OF vga_tb IS
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

    SIGNAL done : BOOLEAN := FALSE;

    CONSTANT clk_period : TIME := 40 ns; -- 25 MHz

    -- VGA constants (must match DUT)
    CONSTANT h_pixels : INTEGER := 800;
    CONSTANT v_lines : INTEGER := 525;
    CONSTANT h_pulse : INTEGER := 96;
    CONSTANT h_bp : INTEGER := 48;
    CONSTANT h_fp : INTEGER := 16;
    CONSTANT v_pulse : INTEGER := 2;
    CONSTANT v_bp : INTEGER := 33;
    CONSTANT vis_w : INTEGER := 640;
    CONSTANT vis_h : INTEGER := 480;

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
        FILE ppm : text OPEN write_mode IS "frame.ppm";
        VARIABLE L : line;
        VARIABLE line_idx : INTEGER := 0;
        VARIABLE px : INTEGER := 0;
        VARIABLE r, g, b : INTEGER := 0;
        VARIABLE started : BOOLEAN := false;
        VARIABLE lines_since_vsync_rise : INTEGER := 0;
        VARIABLE pix_since_hsync_rise : INTEGER := 0;
    BEGIN
        -- initial reset and positions
        reset <= '1';
        ball_x <= STD_LOGIC_VECTOR(to_unsigned(100, 32));
        ball_y <= STD_LOGIC_VECTOR(to_unsigned(120, 32));
        paddle1_pos <= STD_LOGIC_VECTOR(to_unsigned(180, 32));
        paddle2_pos <= STD_LOGIC_VECTOR(to_unsigned(220, 32));
        WAIT FOR clk_period * 10;
        reset <= '0';

        -- wait for vsync rising (end of sync pulse)
        WAIT UNTIL rising_edge(vsync);
        started := true;
        lines_since_vsync_rise := 0;

        -- write PPM header
        write(L, STRING'("P3"));
        writeline(ppm, L);
        write(L, INTEGER'image(vis_w) & " " & INTEGER'image(vis_h));
        writeline(ppm, L);
        write(L, STRING'("255"));
        writeline(ppm, L);

        -- capture one visible frame
        WHILE lines_since_vsync_rise < v_bp + vis_h LOOP
            -- wait start of line (hsync rising)
            WAIT UNTIL rising_edge(hsync);
            pix_since_hsync_rise := 0;

            -- iterate full line worth of pixels
            FOR x IN 0 TO h_pixels - 1 LOOP
                WAIT UNTIL rising_edge(clk25);

                -- only record visible region
                IF (lines_since_vsync_rise >= v_bp) AND
                    (pix_since_hsync_rise >= h_bp) AND
                    (pix_since_hsync_rise < h_bp + vis_w) AND
                    (lines_since_vsync_rise < v_bp + vis_h) THEN

                    -- map 1-bit per channel to 0/255
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
                    -- end of line: newline mainly for readability
                    IF (pix_since_hsync_rise - h_bp) = vis_w - 1 THEN
                        writeline(ppm, L);
                    END IF;
                END IF;

                pix_since_hsync_rise := pix_since_hsync_rise + 1;
            END LOOP;

            lines_since_vsync_rise := lines_since_vsync_rise + 1;
        END LOOP;

        -- done
        WAIT FOR 1 us;
        REPORT "*** VGA Testbench Over ***" SEVERITY note;
        REPORT "PPM frame written to frame.ppm" SEVERITY note;
        done <= TRUE;
        WAIT;
    END PROCESS;

END tb;