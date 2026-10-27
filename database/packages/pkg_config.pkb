-- Extracted unchanged from database_export_with_seed_data.sql (lines 705-713).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_CONFIG" AS
    FUNCTION fn_get_number(p_key IN VARCHAR2) RETURN NUMBER IS
	v_value na_config.config_value%TYPE;
    BEGIN
	SELECT config_value INTO v_value FROM na_config WHERE config_key = p_key;
	RETURN TO_NUMBER(v_value);
    END fn_get_number;
END pkg_config;
/
