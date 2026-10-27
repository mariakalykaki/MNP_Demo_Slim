-- Extracted unchanged from database_export_with_seed_data.sql (lines 838-895).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_RISK" AS

    FUNCTION fn_factor_applies(p_code IN VARCHAR2, p_act IN na_activations%ROWTYPE) RETURN BOOLEAN IS
	v_count    NUMBER;
	v_created  na_customers.created_at%TYPE;
    BEGIN
	CASE p_code
	    WHEN 'R1' THEN  -- request velocity
		SELECT COUNT(*) INTO v_count
		  FROM na_activations
		 WHERE customer_id = p_act.customer_id
		   AND id <> p_act.id
		   AND created_at >= SYSTIMESTAMP - NUMTODSINTERVAL(pkg_config.fn_get_number('VELOCITY_WINDOW_HOURS'), 'HOUR');
		RETURN v_count >= pkg_config.fn_get_number('VELOCITY_LIMIT');
	    WHEN 'R2' THEN  -- new account
		SELECT created_at INTO v_created FROM na_customers WHERE customer_id = p_act.customer_id;
		RETURN v_created > SYSTIMESTAMP - NUMTODSINTERVAL(pkg_config.fn_get_number('NEW_ACCOUNT_DAYS'), 'DAY');
	    WHEN 'R3' THEN  -- premium range
		SELECT COUNT(*) INTO v_count
		  FROM na_number_ranges
		 WHERE range_code = 'PREMIUM' AND p_act.msisdn LIKE prefix || '%';
		RETURN v_count > 0;
	    WHEN 'R4' THEN  -- prepaid and not ID verified
		RETURN p_act.customer_type = 'PREPAID' AND p_act.id_verified = 'N';
	    ELSE
		RAISE_APPLICATION_ERROR(-20012, 'Unknown risk factor: ' || p_code);
	END CASE;
    END fn_factor_applies;

    PROCEDURE pr_score(p_activation_id IN NUMBER) IS
	v_act	   na_activations%ROWTYPE;
	v_score    NUMBER := 0;
	v_factors  VARCHAR2(100);
	v_decision na_activations.risk_decision%TYPE;
    BEGIN
	SELECT * INTO v_act FROM na_activations WHERE id = p_activation_id;

	FOR f IN (SELECT factor_code, points FROM na_risk_factors WHERE active_flag = 'Y' ORDER BY factor_code) LOOP
	    IF fn_factor_applies(f.factor_code, v_act) THEN
		v_score := v_score + f.points;
		v_factors := CASE WHEN v_factors IS NULL THEN f.factor_code ELSE v_factors || ',' || f.factor_code END;
	    END IF;
	END LOOP;

	v_decision := CASE
	    WHEN v_score >= pkg_config.fn_get_number('RISK_REJECT_MIN')        THEN 'REJECT'
	    WHEN v_score >= pkg_config.fn_get_number('RISK_MANUAL_REVIEW_MIN') THEN 'MANUAL_REVIEW'
	    ELSE 'AUTO_APPROVE'
	END;

	UPDATE na_activations
	   SET risk_score = v_score, risk_factors = v_factors, risk_decision = v_decision,
	       updated_at = SYSTIMESTAMP
	 WHERE id = p_activation_id;
    END pr_score;

END pkg_risk;
/
