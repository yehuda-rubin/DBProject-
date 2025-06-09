-- Procedure to assign a maintenance task to a personnel member
CREATE OR REPLACE PROCEDURE assign_maintenance_task(
    p_personnel_id INT,
    p_maintenance_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO Performs (personnel_id, maintenance_id)
    VALUES (p_personnel_id, p_maintenance_id);
    
    RAISE NOTICE 'Maintenance task assigned successfully.';
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to assign task: %', SQLERRM;
END;
$$;
