-- Extracted unchanged from database_export_with_seed_data.sql (lines 580-585).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_TIMERS" AS
    PROCEDURE pr_start_timer(p_activation_id IN NUMBER, p_timer_code IN VARCHAR2);
    PROCEDURE pr_cancel_all(p_activation_id IN NUMBER);
    FUNCTION fn_fire_due RETURN NUMBER;
END pkg_timers;
/
