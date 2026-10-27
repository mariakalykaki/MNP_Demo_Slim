-- Extracted unchanged from database_export_with_seed_data.sql (lines 559-573).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_OUTBOX" AS
    PROCEDURE pr_enqueue(p_activation_id IN NUMBER, p_notification_code IN VARCHAR2);

    PROCEDURE pr_claim_next(
	p_id		    OUT NUMBER,
	p_activation_id     OUT NUMBER,
	p_notification_code OUT VARCHAR2,
	p_audience	    OUT VARCHAR2,
	p_channel	    OUT VARCHAR2,
	p_payload	    OUT VARCHAR2
    );
    PROCEDURE pr_mark_published(p_id IN NUMBER);
    PROCEDURE pr_mark_failed(p_id IN NUMBER, p_error IN VARCHAR2);
END pkg_outbox;
/
