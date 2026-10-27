-- Extracted unchanged from database_export_with_seed_data.sql (lines 575-578).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_RISK" AS
    PROCEDURE pr_score(p_activation_id IN NUMBER);
END pkg_risk;
/
