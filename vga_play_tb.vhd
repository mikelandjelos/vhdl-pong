LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE std.textio.ALL;

-- Minimal playable Pong renderer for ffplay/ffmpeg.
-- Streams raw RGB24 frames to OUT_PATH (FIFO/file). Reads controls from CTRL_PATH.
-- Controls file contains a single integer mask:
--   bit0=P1_up, bit1=P1_down, bit2=P2_up, bit3=P2_down; -1 to quit.

ENTITY vga_play_tb IS
    GENERIC (
        WIDTH : INTEGER := 640;
        HEIGHT : INTEGER := 480;
        N_FRAMES : INTEGER := 0; -- 0 => run until quit
        FRAMERATE : INTEGER := 120; -- higher FPS for snappier input
        OUT_PATH : STRING := "frames/stream.rgb";
        CTRL_PATH : STRING := "frames/controls.txt"
    );
END vga_play_tb;

ARCHITECTURE tb OF vga_play_tb IS

    TYPE char_file IS FILE OF CHARACTER;

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

    CONSTANT PAD_W : INTEGER := 8;
    CONSTANT PAD_H : INTEGER := 60;
    CONSTANT BALL : INTEGER := 8;
    CONSTANT P1_X : INTEGER := 16;
    CONSTANT P2_X : INTEGER := WIDTH - 16 - PAD_W;

    -- Safe control reader: keeps previous mask if file absent/empty
    PROCEDURE read_control(CONSTANT path : IN STRING; VARIABLE mask : INOUT INTEGER) IS
        FILE ctrl : text;
        VARIABLE st : FILE_OPEN_STATUS;
        VARIABLE L : line;
        VARIABLE val : INTEGER;
        VARIABLE good : BOOLEAN;
        VARIABLE last_is_neg : BOOLEAN := FALSE;
    BEGIN
        FILE_OPEN(st, ctrl, path, READ_MODE);
        IF st = OPEN_OK THEN
            WHILE NOT ENDFILE(ctrl) LOOP
                READLINE(ctrl, L);
                READ(L, val, good);
                IF good THEN
                    last_is_neg := (val < 0);
                    IF NOT last_is_neg THEN
                        mask := val; -- keep last non-negative
                    END IF;
                END IF;
            END LOOP;
            FILE_CLOSE(ctrl);
        END IF;
        IF last_is_neg THEN
            mask := - 1; -- quit only if the last parsed value is negative
        END IF;
    END PROCEDURE;

    FUNCTION bit_set(n : INTEGER; k : INTEGER) RETURN BOOLEAN IS
    BEGIN
        RETURN ((n / INTEGER(2 ** k)) MOD 2) = 1;
    END FUNCTION;

BEGIN

    PROCESS
        FILE f : char_file;
        VARIABLE p1y, p2y : INTEGER := (HEIGHT - PAD_H) / 2;
        VARIABLE bx, by : INTEGER := WIDTH/2;
        VARIABLE dx, dy : INTEGER := 4; -- per-frame pixels
        VARIABLE r, g, b : INTEGER;
        VARIABLE mask : INTEGER := 0; -- sticky control mask
        VARIABLE frame : INTEGER := 0;
        CONSTANT frame_delay : TIME := INTEGER(1000 / FRAMERATE) * 1 ms;
    BEGIN
        FILE_OPEN(f, OUT_PATH, WRITE_MODE);

        WHILE (N_FRAMES = 0) OR (frame < N_FRAMES) LOOP
            -- controls (sticky). Writer can 'echo <n> > CTRL_PATH'
            read_control(CTRL_PATH, mask);
            IF mask < 0 THEN
                EXIT;
            END IF;

            -- apply controls (instant directions: up = negative Y, down = positive Y)
            IF bit_set(mask, 0) AND NOT bit_set(mask, 1) THEN
                p1y := p1y - 16;
            END IF; -- P1 up
            IF bit_set(mask, 1) AND NOT bit_set(mask, 0) THEN
                p1y := p1y + 16;
            END IF; -- P1 down
            IF bit_set(mask, 2) AND NOT bit_set(mask, 3) THEN
                p2y := p2y - 16;
            END IF; -- P2 up
            IF bit_set(mask, 3) AND NOT bit_set(mask, 2) THEN
                p2y := p2y + 16;
            END IF; -- P2 down
            IF p1y < 0 THEN
                p1y := 0;
            ELSIF p1y > HEIGHT - PAD_H THEN
                p1y := HEIGHT - PAD_H;
            END IF;
            IF p2y < 0 THEN
                p2y := 0;
            ELSIF p2y > HEIGHT - PAD_H THEN
                p2y := HEIGHT - PAD_H;
            END IF;

            -- ball motion (per-frame)
            bx := bx + dx;
            by := by + dy;
            IF by <= 0 THEN
                by := 0;
                dy := ABS(dy);
            END IF;
            IF by >= HEIGHT - BALL THEN
                by := HEIGHT - BALL;
                dy := - ABS(dy);
            END IF;

            -- paddle collisions
            IF (bx <= P1_X + PAD_W) AND (bx >= P1_X - BALL) THEN
                IF (by + BALL > p1y) AND (by < p1y + PAD_H) THEN
                    dx := ABS(dx);
                    bx := P1_X + PAD_W;
                END IF;
            END IF;
            IF (bx + BALL >= P2_X) AND (bx <= P2_X + PAD_W) THEN
                IF (by + BALL > p2y) AND (by < p2y + PAD_H) THEN
                    dx := - ABS(dx);
                    bx := P2_X - BALL;
                END IF;
            END IF;
            -- scoring => reset ball to center, head to scorer
            IF bx <- BALL THEN
                bx := WIDTH/2;
                by := HEIGHT/2;
                dx := ABS(dx);
            END IF;
            IF bx > WIDTH + BALL THEN
                bx := WIDTH/2;
                by := HEIGHT/2;
                dx := - ABS(dx);
            END IF;

            -- render frame (RGB24)
            FOR y IN 0 TO HEIGHT - 1 LOOP
                FOR x IN 0 TO WIDTH - 1 LOOP
                    IF (x >= P1_X) AND (x < P1_X + PAD_W) AND (y >= p1y) AND (y < p1y + PAD_H) THEN
                        r := 0;
                        g := 255;
                        b := 0;
                    ELSIF (x >= P2_X) AND (x < P2_X + PAD_W) AND (y >= p2y) AND (y < p2y + PAD_H) THEN
                        r := 0;
                        g := 255;
                        b := 0;
                    ELSIF (x >= bx) AND (x < bx + BALL) AND (y >= by) AND (y < by + BALL) THEN
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

            frame := frame + 1;
            WAIT FOR frame_delay;
        END LOOP;

        FILE_CLOSE(f);
        ASSERT FALSE REPORT "vga_play_tb: stopped" SEVERITY note;
        WAIT;
    END PROCESS;

END tb;