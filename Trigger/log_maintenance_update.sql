-- Trigger function to log maintenance activity after update
CREATE OR REPLACE FUNCTION log_maintenance_update()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE 'Maintenance record % was updated. New date: %, Cost: %',
        NEW.maintenance_id, NEW.next_due, NEW.cost_of_repair;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call log function after an update on Maintenance table
CREATE TRIGGER trg_log_maintenance
AFTER UPDATE ON Maintenance
FOR EACH ROW
EXECUTE FUNCTION log_maintenance_update();
