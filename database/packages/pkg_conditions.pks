-- Extracted unchanged from database_export_with_seed_data.sql (lines 544-547).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_CONDITIONS" AS
    FUNCTION fn_evaluate(p_condition_name IN VARCHAR2, p_activation_id IN NUMBER) RETURN BOOLEAN;
END pkg_conditions;
/
