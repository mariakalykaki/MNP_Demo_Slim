-- Extracted unchanged from database_export_with_seed_data.sql (lines 554-557).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_ELIGIBILITY" AS
    FUNCTION fn_check(p_activation_id IN NUMBER) RETURN VARCHAR2;
END pkg_eligibility;
/
