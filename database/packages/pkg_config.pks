-- Extracted unchanged from database_export_with_seed_data.sql (lines 549-552).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_CONFIG" AS
    FUNCTION fn_get_number(p_key IN VARCHAR2) RETURN NUMBER;
END pkg_config;
/
