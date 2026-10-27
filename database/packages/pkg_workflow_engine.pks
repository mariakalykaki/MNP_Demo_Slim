-- Extracted unchanged from database_export_with_seed_data.sql (lines 587-595).
CREATE OR REPLACE EDITIONABLE PACKAGE "NA_APP"."PKG_WORKFLOW_ENGINE" AS
    PROCEDURE pr_process_event(
	p_activation_id IN NUMBER,
	p_status	IN VARCHAR2,
	p_event_type	IN VARCHAR2,
	p_context	IN VARCHAR2 DEFAULT NULL
    );
END pkg_workflow_engine;
/
