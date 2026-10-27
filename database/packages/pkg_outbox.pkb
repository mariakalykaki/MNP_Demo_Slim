-- Extracted unchanged from database_export_with_seed_data.sql (lines 777-836).
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "NA_APP"."PKG_OUTBOX" AS

    PROCEDURE pr_enqueue(p_activation_id IN NUMBER, p_notification_code IN VARCHAR2) IS
	v_payload VARCHAR2(1000);
	v_count   NUMBER;
    BEGIN
	SELECT COUNT(*) INTO v_count FROM na_notification_types WHERE notification_code = p_notification_code;
	IF v_count = 0 THEN
	    RAISE_APPLICATION_ERROR(-20015, 'Unknown notification code: ' || p_notification_code);
	END IF;

	SELECT JSON_OBJECT(
		   'activationId' VALUE id,
		   'msisdn'	  VALUE msisdn,
		   'customerId'   VALUE customer_id,
		   'status'	  VALUE status,
		   'notification' VALUE p_notification_code
	       )
	  INTO v_payload
	  FROM na_activations WHERE id = p_activation_id;

	INSERT INTO na_outbox (activation_id, notification_code, payload)
	VALUES (p_activation_id, p_notification_code, v_payload);
    END pr_enqueue;

    PROCEDURE pr_claim_next(
	p_id		    OUT NUMBER,
	p_activation_id     OUT NUMBER,
	p_notification_code OUT VARCHAR2,
	p_audience	    OUT VARCHAR2,
	p_channel	    OUT VARCHAR2,
	p_payload	    OUT VARCHAR2
    ) IS
    BEGIN
	SELECT id, activation_id, notification_code, payload
	  INTO p_id, p_activation_id, p_notification_code, p_payload
	  FROM na_outbox
	 WHERE status = 'PENDING' AND ROWNUM = 1
	   FOR UPDATE SKIP LOCKED;

	UPDATE na_outbox SET status = 'IN_FLIGHT', attempts = attempts + 1 WHERE id = p_id;

	SELECT audience, channel INTO p_audience, p_channel
	  FROM na_notification_types WHERE notification_code = p_notification_code;
    EXCEPTION WHEN NO_DATA_FOUND THEN
	p_id := NULL;
    END pr_claim_next;

    PROCEDURE pr_mark_published(p_id IN NUMBER) IS
    BEGIN
	UPDATE na_outbox SET status = 'PUBLISHED', published_at = SYSTIMESTAMP WHERE id = p_id;
    END pr_mark_published;

    PROCEDURE pr_mark_failed(p_id IN NUMBER, p_error IN VARCHAR2) IS
    BEGIN
	UPDATE na_outbox SET status = 'FAILED', error_message = SUBSTR(p_error, 1, 400) WHERE id = p_id;
    END pr_mark_failed;

END pkg_outbox;
/
