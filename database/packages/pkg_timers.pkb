-- Extracted unchanged from database_export_with_seed_data.sql (lines 897-947).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_TIMERS" AS

    PROCEDURE pr_start_timer(p_activation_id IN NUMBER, p_timer_code IN VARCHAR2) IS
	v_seconds na_timer_types.duration_seconds%TYPE;
    BEGIN
	BEGIN
	    SELECT duration_seconds INTO v_seconds FROM na_timer_types WHERE timer_code = p_timer_code;
	EXCEPTION WHEN NO_DATA_FOUND THEN
	    RAISE_APPLICATION_ERROR(-20011, 'Unknown timer code: ' || p_timer_code);
	END;

	INSERT INTO na_timers (activation_id, timer_code, due_at)
	VALUES (p_activation_id, p_timer_code, SYSTIMESTAMP + NUMTODSINTERVAL(v_seconds, 'SECOND'));
    END pr_start_timer;

    PROCEDURE pr_cancel_all(p_activation_id IN NUMBER) IS
    BEGIN
	UPDATE na_timers SET status = 'CANCELLED'
	 WHERE activation_id = p_activation_id AND status = 'PENDING';
    END pr_cancel_all;

    FUNCTION fn_fire_due RETURN NUMBER IS
	v_fired NUMBER := 0;
	v_error VARCHAR2(400);
    BEGIN
	FOR t IN (
	    SELECT tm.id, tm.activation_id, tt.fires_event
	      FROM na_timers tm
	      JOIN na_timer_types tt ON tt.timer_code = tm.timer_code
	     WHERE tm.status = 'PENDING' AND tm.due_at <= SYSTIMESTAMP
	     ORDER BY tm.due_at
	       FOR UPDATE OF tm.status SKIP LOCKED
	) LOOP
	    SAVEPOINT before_timer;
	    BEGIN
		UPDATE na_timers SET status = 'FIRED', fired_at = SYSTIMESTAMP WHERE id = t.id;
		pkg_activations.pr_raise_event(t.activation_id, t.fires_event);
		v_fired := v_fired + 1;
	    EXCEPTION WHEN OTHERS THEN
		v_error := SUBSTR(SQLERRM, 1, 400);
		ROLLBACK TO before_timer;
		UPDATE na_timers
		   SET status = 'FAILED', error_message = v_error
		 WHERE id = t.id;
	    END;
	END LOOP;
	RETURN v_fired;
    END fn_fire_due;

END pkg_timers;
/
