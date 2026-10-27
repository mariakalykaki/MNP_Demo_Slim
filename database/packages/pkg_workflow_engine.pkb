-- Extracted unchanged from database_export_with_seed_data.sql (lines 949-1040).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_WORKFLOW_ENGINE" AS

    PROCEDURE pr_run_actions(p_activation_id IN NUMBER, p_branch_id IN NUMBER, p_detail IN OUT VARCHAR2) IS
	v_rows NUMBER;
    BEGIN
	FOR act IN (
	    SELECT action_type, action_parameter
	      FROM na_workflow_actions
	     WHERE branch_id = p_branch_id
	     ORDER BY action_sequence
	) LOOP
	    CASE act.action_type
		WHEN 'TRANSITION_TO' THEN
		    UPDATE na_activations SET status = act.action_parameter, updated_at = SYSTIMESTAMP
		     WHERE id = p_activation_id;

		WHEN 'NOTIFY' THEN
		    pkg_outbox.pr_enqueue(p_activation_id, act.action_parameter);

		WHEN 'START_TIMER' THEN
		    pkg_timers.pr_start_timer(p_activation_id, act.action_parameter);

		WHEN 'STOP_ALL_TIMERS' THEN
		    pkg_timers.pr_cancel_all(p_activation_id);

		WHEN 'RESERVE_NUMBER' THEN
		    UPDATE na_number_pool p SET status = 'RESERVED', reserved_by_id = p_activation_id, updated_at = SYSTIMESTAMP
		     WHERE status = 'AVAILABLE'
		       AND msisdn = (SELECT msisdn FROM na_activations WHERE id = p_activation_id);
		    v_rows := SQL%ROWCOUNT;
		    IF v_rows = 0 THEN
			RAISE_APPLICATION_ERROR(-20014, 'Number is no longer available.');
		    END IF;

		WHEN 'RELEASE_NUMBER' THEN
		    UPDATE na_number_pool SET status = 'AVAILABLE', reserved_by_id = NULL, updated_at = SYSTIMESTAMP
		     WHERE reserved_by_id = p_activation_id;

		WHEN 'ACTIVATE_NUMBER' THEN
		    UPDATE na_number_pool SET status = 'ACTIVE', updated_at = SYSTIMESTAMP
		     WHERE reserved_by_id = p_activation_id;

		WHEN 'FLAG_ESCALATED' THEN
		    UPDATE na_activations SET escalated_flag = 'Y', updated_at = SYSTIMESTAMP
		     WHERE id = p_activation_id;

		ELSE
		    RAISE_APPLICATION_ERROR(-20013, 'Unknown action type: ' || act.action_type);
	    END CASE;

	    p_detail := CASE WHEN p_detail IS NULL THEN '' ELSE p_detail || ',' END
			|| act.action_type || CASE WHEN act.action_parameter IS NOT NULL THEN ':' || act.action_parameter END;
	END LOOP;
    END pr_run_actions;

    PROCEDURE pr_process_event(
	p_activation_id IN NUMBER,
	p_status	IN VARCHAR2,
	p_event_type	IN VARCHAR2,
	p_context	IN VARCHAR2 DEFAULT NULL
    ) IS
	v_branch_id NUMBER := NULL;
	v_detail    VARCHAR2(400) := CASE WHEN p_context IS NOT NULL THEN 'context=' || p_context END;
	v_to_status na_activations.status%TYPE;
    BEGIN
	FOR br IN (
	    SELECT id, condition_name
	      FROM na_workflow_branches
	     WHERE status = p_status AND event_type = p_event_type
	     ORDER BY branch_sequence
	) LOOP
	    IF br.condition_name IS NULL OR pkg_conditions.fn_evaluate(br.condition_name, p_activation_id) THEN
		v_branch_id := br.id;
		EXIT;
	    END IF;
	END LOOP;

	IF v_branch_id IS NULL THEN
	    RAISE_APPLICATION_ERROR(-20010,
		'Event ' || p_event_type || ' is not valid while the activation is ' || p_status || '.');
	END IF;

	pr_run_actions(p_activation_id, v_branch_id, v_detail);

	SELECT status INTO v_to_status FROM na_activations WHERE id = p_activation_id;

	INSERT INTO na_audit_log (activation_id, event_type, from_status, to_status, branch_id, detail)
	VALUES (p_activation_id, p_event_type, p_status, v_to_status, v_branch_id, SUBSTR(v_detail, 1, 400));
    END pr_process_event;

END pkg_workflow_engine;
/
