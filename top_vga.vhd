LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY top_vga IS
    GENERIC (
        -- clk_div produces f_out = f_in / (2*DIVISOR)
        PIX_DIVISOR : INTEGER := 2; -- 100 MHz -> 25 MHz
        TICK_DIVISOR : INTEGER := 5000000 -- ~10 Hz animation tick (100 MHz / (2*5e6) = 10 Hz)
    );
    PORT (
        clk : IN STD_LOGIC; -- 100 MHz
        rst : IN STD_LOGIC;
        hsync : OUT STD_LOGIC;
        vsync : OUT STD_LOGIC;
        rgb : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
    );
END top_vga;

ARCHITECTURE rtl OF top_vga IS
    COMPONENT clk_div IS
        GENERIC (
            DIVISOR : INTEGER := 50000000
        );
        PORT (
            clk_in : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            clk_out : OUT STD_LOGIC
        );
    END COMPONENT;

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

    SIGNAL clk_pix : STD_LOGIC;
    SIGNAL clk_tick : STD_LOGIC;

    -- positions
    SIGNAL ball_x : INTEGER := 100;
    SIGNAL ball_y : INTEGER := 100;
    SIGNAL paddle1_pos : INTEGER := 180;
    SIGNAL paddle2_pos : INTEGER := 220;

    SIGNAL dx : INTEGER := 2;
    SIGNAL dy : INTEGER := 2;

    -- conversion signals for port map
    SIGNAL ball_x_vec : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL ball_y_vec : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL paddle1_pos_vec : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL paddle2_pos_vec : STD_LOGIC_VECTOR(31 DOWNTO 0);

BEGIN

    -- 25 MHz pixel clock
    u_pix : clk_div
    GENERIC MAP(DIVISOR => PIX_DIVISOR)
    PORT MAP(
        clk_in => clk,
        rst => rst,
        clk_out => clk_pix
    );

    -- Slow tick for animation
    u_tick : clk_div
    GENERIC MAP(DIVISOR => TICK_DIVISOR)
    PORT MAP(
        clk_in => clk,
        rst => rst,
        clk_out => clk_tick
    );

    -- simple animation/bounce within 640x480 bounds
    PROCESS (clk_tick, rst)
    BEGIN
        IF rst = '1' THEN
            ball_x <= 100;
            ball_y <= 100;
            paddle1_pos <= 180;
            paddle2_pos <= 220;
            dx <= 2;
            dy <= 2;
        ELSIF rising_edge(clk_tick) THEN
            -- move ball
            ball_x <= ball_x + dx;
            ball_y <= ball_y + dy;

            IF (ball_x <= 0) OR (ball_x >= 640 - 8) THEN
                dx <= - dx;
            END IF;
            IF (ball_y <= 0) OR (ball_y >= 480 - 8) THEN
                dy <= - dy;
            END IF;

            -- simple paddle motion
            paddle1_pos <= (paddle1_pos + 3) MOD (480 - 60);
            paddle2_pos <= (paddle2_pos + 2) MOD (480 - 60);
        END IF;
    END PROCESS;

    -- integer to std_logic_vector conversions
    ball_x_vec <= STD_LOGIC_VECTOR(to_unsigned(ball_x, 32));
    ball_y_vec <= STD_LOGIC_VECTOR(to_unsigned(ball_y, 32));
    paddle1_pos_vec <= STD_LOGIC_VECTOR(to_unsigned(paddle1_pos, 32));
    paddle2_pos_vec <= STD_LOGIC_VECTOR(to_unsigned(paddle2_pos, 32));

    -- drive controller
    u_vga : vga_controller
    PORT MAP(
        clk => clk_pix,
        reset => rst,
        ball_x => ball_x_vec,
        ball_y => ball_y_vec,
        paddle1_pos => paddle1_pos_vec,
        paddle2_pos => paddle2_pos_vec,
        hsync => hsync,
        vsync => vsync,
        rgb => rgb
    );

END rtl;