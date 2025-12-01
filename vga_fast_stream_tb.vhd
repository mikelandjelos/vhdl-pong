LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

-- Fast functional renderer: streams raw RGB frames (no VGA timing) to a binary file.
-- Intended for piping to ffplay/ffmpeg via a named pipe for live preview.

ENTITY vga_fast_stream_tb IS
    GENERIC (
        WIDTH : INTEGER := 640;
        HEIGHT : INTEGER := 480;
        N_FRAMES : INTEGER := 120;
        FRAMERATE : INTEGER := 30; -- informational only (used by consumer)
        OUT_PATH : STRING := "frames/stream.rgb"
    );
END vga_fast_stream_tb;

ARCHITECTURE tb OF vga_fast_stream_tb IS

    -- binary file type
    TYPE char_file IS FILE OF CHARACTER;

    -- byte helper
    FUNCTION byte(v : INTEGER) RETURN CHARACTER IS
    BEGIN
        IF v <= 0 THEN
            RETURN CHARACTER'VAL(0);
        ELSIF v >= 255 THEN
            RETURN CHARACTER'VAL(255);
        ELSE
            RETURN CHARACTER'VAL(v);
        END IF;
    END FUNCTION;

    -- scene constants (match vga_controller geometry)
    CONSTANT PADDLE_W : INTEGER := 8;
    CONSTANT PADDLE_H : INTEGER := 60;
    CONSTANT BALL_SIZE : INTEGER := 8;
    CONSTANT P1_X : INTEGER := 16;
    CONSTANT P2_X : INTEGER := 640 - 16 - PADDLE_W;

BEGIN

    PROCESS
        FILE f : char_file;
        VARIABLE bx, by : INTEGER := 100;
        VARIABLE p1y, p2y : INTEGER := 180;
        VARIABLE dx, dy : INTEGER := 4;
        VARIABLE x, y : INTEGER;
        VARIABLE r, g, b : INTEGER;
    BEGIN
        -- open stream (can be a FIFO created by the shell)
        FILE_OPEN(f, OUT_PATH, WRITE_MODE);

        FOR frame IN 0 TO N_FRAMES - 1 LOOP
            -- draw one frame (row-major)
            FOR y IN 0 TO HEIGHT - 1 LOOP
                FOR x IN 0 TO WIDTH - 1 LOOP
                    -- paddles (green)
                    IF (x >= P1_X) AND (x < P1_X + PADDLE_W) AND (y >= p1y) AND (y < p1y + PADDLE_H) THEN
                        r := 0;
                        g := 255;
                        b := 0;
                    ELSIF (x >= P2_X) AND (x < P2_X + PADDLE_W) AND (y >= p2y) AND (y < p2y + PADDLE_H) THEN
                        r := 0;
                        g := 255;
                        b := 0;
                        -- ball (white)
                    ELSIF (x >= bx) AND (x < bx + BALL_SIZE) AND (y >= by) AND (y < by + BALL_SIZE) THEN
                        r := 255;
                        g := 255;
                        b := 255;
                    ELSE
                        r := 0;
                        g := 0;
                        b := 0;
                    END IF;

                    WRITE(f, byte(r));
                    WRITE(f, byte(g));
                    WRITE(f, byte(b));
                END LOOP;
            END LOOP;

            -- animate
            bx := bx + dx;
            by := by + dy;
            IF (bx <= 0) OR (bx >= WIDTH - BALL_SIZE) THEN
                dx := - dx;
                bx := bx + dx;
            END IF;
            IF (by <= 0) OR (by >= HEIGHT - BALL_SIZE) THEN
                dy := - dy;
                by := by + dy;
            END IF;
            p1y := (p1y + 5) MOD (HEIGHT - PADDLE_H);
            p2y := (p2y + 3) MOD (HEIGHT - PADDLE_H);
        END LOOP;

        FILE_CLOSE(f);
        ASSERT FALSE REPORT "vga_fast_stream_tb: stream finished" SEVERITY note;
        WAIT;
    END PROCESS;

END tb;