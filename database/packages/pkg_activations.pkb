-- Extracted unchanged from database_export_with_seed_data.sql (lines 600-685).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_ACTIVATIONS" AS

    PROCEDURE pr_assert_exists(p_activation_id IN NUMBER) IS
	v_count NUMBER;
    BEGIN
	SELECT COUNT(*) INTO v_count FROM na_activations WHERE id = p_activation_id;
	IF v_count = 0 THEN
	    RAISE_APPLICATION_ERROR(-20003, 'Activation ' || p_activation_id || ' not found.');
	END IF;
    END pr_assert_exists;

    FUNCTION fn_submit(
	p_msisdn	IN VARCHAR2,
	p_customer_id	IN VARCHAR2,
	p_customer_type IN VARCHAR2,
	p_id_verified	IN VARCHAR2,
	p_plan_code	IN VARCHAR2
    ) RETURN NUMBER IS
	v_id	  NUMBER;
	v_count   NUMBER;
	v_status  na_activations.status%TYPE;
	v_reasons VARCHAR2(200);
    BEGIN
	IF p_msisdn IS NULL OR p_customer_id IS NULL OR p_plan_code IS NULL
	   OR p_customer_type IS NULL OR p_customer_type NOT IN ('PREPAID', 'POSTPAID')
	   OR p_id_verified IS NULL OR p_id_verified NOT IN ('Y', 'N') THEN
	    RAISE_APPLICATION_ERROR(-20001,
		'msisdn, customerId and planCode are required; customerType must be PREPAID or POSTPAID.');
	END IF;

	SELECT COUNT(*) INTO v_count FROM na_customers WHERE customer_id = p_customer_id;
	IF v_count = 0 THEN
	    RAISE_APPLICATION_ERROR(-20003, 'Customer ' || p_customer_id || ' not found.');
	END IF;

	INSERT INTO na_activations (msisdn, customer_id, customer_type, id_verified, plan_code)
	VALUES (p_msisdn, p_customer_id, p_customer_type, p_id_verified, p_plan_code)
	RETURNING id INTO v_id;

	v_reasons := pkg_eligibility.fn_check(v_id);
	UPDATE na_activations SET rejection_reasons = v_reasons WHERE id = v_id;

	pr_raise_event(v_id, 'REQUEST_RECEIVED');

	SELECT status INTO v_status FROM na_activations WHERE id = v_id;
	IF v_status = 'ELIGIBLE' THEN
	    pkg_risk.pr_score(v_id);
	    pr_raise_event(v_id, 'RISK_SCORED');
	END IF;

	RETURN v_id;
    END fn_submit;

    PROCEDURE pr_raise_event(
	p_activation_id IN NUMBER,
	p_event_type	IN VARCHAR2,
	p_context	IN VARCHAR2 DEFAULT NULL
    ) IS
	v_status na_activations.status%TYPE;
    BEGIN
	pr_assert_exists(p_activation_id);
	SELECT status INTO v_status FROM na_activations WHERE id = p_activation_id FOR UPDATE;
	pkg_workflow_engine.pr_process_event(p_activation_id, v_status, p_event_type, p_context);
    END pr_raise_event;

    PROCEDURE pr_get(p_activation_id IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
	pr_assert_exists(p_activation_id);
	OPEN p_cursor FOR
	    SELECT id, msisdn, customer_id, customer_type, id_verified, plan_code, status,
		   rejection_reasons, risk_score, risk_factors, risk_decision, escalated_flag,
		   created_at, updated_at
	      FROM na_activations WHERE id = p_activation_id;
    END pr_get;

    PROCEDURE pr_get_audit(p_activation_id IN NUMBER, p_cursor OUT SYS_REFCURSOR) IS
    BEGIN
	pr_assert_exists(p_activation_id);
	OPEN p_cursor FOR
	    SELECT event_type, from_status, to_status, detail, occurred_at
	      FROM na_audit_log WHERE activation_id = p_activation_id
	     ORDER BY occurred_at, id;
    END pr_get_audit;

END pkg_activations;
/
