LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE test_helpers IS
    FUNCTION to_string(vec : STD_LOGIC_VECTOR) RETURN STRING;
END PACKAGE test_helpers;

PACKAGE BODY test_helpers IS
    FUNCTION to_string(vec : STD_LOGIC_VECTOR) RETURN STRING IS
        VARIABLE result : STRING(1 TO vec'LENGTH);
        VARIABLE idx : INTEGER;
    BEGIN
        FOR i IN vec'RANGE LOOP
            idx := vec'HIGH - i + 1;
            IF vec(i) = '1' THEN
                result(idx) := '1';
            ELSIF vec(i) = '0' THEN
                result(idx) := '0';
            ELSE
                result(idx) := 'X';
            END IF;
        END LOOP;
        RETURN result;
    END FUNCTION;
END PACKAGE BODY test_helpers;