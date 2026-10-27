-- Extracted unchanged from database_export_with_seed_data.sql (lines 524-542).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_ACTIVATIONS" AS
    FUNCTION fn_submit(
	p_msisdn	IN VARCHAR2,
	p_customer_id	IN VARCHAR2,
	p_customer_type IN VARCHAR2,
	p_id_verified	IN VARCHAR2,
	p_plan_code	IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE pr_raise_event(
	p_activation_id IN NUMBER,
	p_event_type	IN VARCHAR2,
	p_context	IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE pr_get(p_activation_id IN NUMBER, p_cursor OUT SYS_REFCURSOR);
    PROCEDURE pr_get_audit(p_activation_id IN NUMBER, p_cursor OUT SYS_REFCURSOR);
END pkg_activations;
/
