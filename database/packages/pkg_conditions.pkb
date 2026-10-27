-- Extracted unchanged from database_export_with_seed_data.sql (lines 687-703).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_CONDITIONS" AS

    FUNCTION fn_evaluate(p_condition_name IN VARCHAR2, p_activation_id IN NUMBER) RETURN BOOLEAN IS
	v_act na_activations%ROWTYPE;
    BEGIN
	SELECT * INTO v_act FROM na_activations WHERE id = p_activation_id;

	CASE p_condition_name
	    WHEN 'ELIGIBILITY_PASSED' THEN RETURN v_act.rejection_reasons IS NULL;
	    WHEN 'RISK_AUTO_APPROVE'  THEN RETURN v_act.risk_decision = 'AUTO_APPROVE';
	    WHEN 'RISK_MANUAL_REVIEW' THEN RETURN v_act.risk_decision = 'MANUAL_REVIEW';
	    ELSE RAISE_APPLICATION_ERROR(-20012, 'Unknown condition: ' || p_condition_name);
	END CASE;
    END fn_evaluate;

END pkg_conditions;
/
