-- Extracted unchanged from database_export_with_seed_data.sql (lines 715-775).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_ELIGIBILITY" AS

    PROCEDURE pr_add(p_reasons IN OUT VARCHAR2, p_reason IN VARCHAR2) IS
    BEGIN
	p_reasons := CASE WHEN p_reasons IS NULL THEN p_reason ELSE p_reasons || ',' || p_reason END;
    END pr_add;

    FUNCTION fn_check(p_activation_id IN NUMBER) RETURN VARCHAR2 IS
	v_act	   na_activations%ROWTYPE;
	v_balance  na_customers.outstanding_balance%TYPE;
	v_count    NUMBER;
	v_status   na_number_pool.status%TYPE;
	v_reasons  VARCHAR2(200);
    BEGIN
	SELECT * INTO v_act FROM na_activations WHERE id = p_activation_id;
	SELECT outstanding_balance INTO v_balance FROM na_customers WHERE customer_id = v_act.customer_id;

	SELECT COUNT(*) INTO v_count FROM na_number_ranges WHERE v_act.msisdn LIKE prefix || '%';
	IF NOT REGEXP_LIKE(v_act.msisdn, '^\+[1-9][0-9]{7,14}$') OR v_count = 0 THEN
	    pr_add(v_reasons, 'INVALID_NUMBER');
	END IF;

	BEGIN
	    SELECT status INTO v_status FROM na_number_pool WHERE msisdn = v_act.msisdn;
	EXCEPTION WHEN NO_DATA_FOUND THEN
	    v_status := NULL;
	END;
	IF v_status IS NULL OR v_status <> 'AVAILABLE' THEN
	    pr_add(v_reasons, 'NUMBER_UNAVAILABLE');
	END IF;

	IF v_balance > 0 THEN
	    pr_add(v_reasons, 'OUTSTANDING_BALANCE');
	END IF;

	SELECT COUNT(*) INTO v_count
	  FROM na_activations
	 WHERE customer_id = v_act.customer_id AND status = 'ACTIVE';
	IF v_count >= pkg_config.fn_get_number('MAX_ACTIVE_LINES') THEN
	    pr_add(v_reasons, 'LINE_LIMIT_EXCEEDED');
	END IF;

	SELECT COUNT(*) INTO v_count
	  FROM na_activations
	 WHERE customer_id = v_act.customer_id
	   AND msisdn = v_act.msisdn
	   AND id <> v_act.id
	   AND status NOT IN ('REJECTED', 'EXPIRED', 'FAILED', 'CANCELLED', 'ACTIVE');
	IF v_count > 0 THEN
	    pr_add(v_reasons, 'DUPLICATE_REQUEST');
	END IF;

	IF v_act.customer_type = 'PREPAID' AND v_act.plan_code <> 'STARTER' AND v_act.id_verified = 'N' THEN
	    pr_add(v_reasons, 'ID_REQUIRED');
	END IF;

	RETURN v_reasons;
    END fn_check;

END pkg_eligibility;
/
