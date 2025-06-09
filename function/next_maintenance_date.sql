-- Function to return the next maintenance date for a given asset
CREATE OR REPLACE FUNCTION next_maintenance_date(asset_id_input INT)
RETURNS DATE AS $$
DECLARE
    next_date DATE;
BEGIN
    SELECT next_due INTO next_date
    FROM Maintenance
    JOIN Requires ON Maintenance.maintenance_id = Requires.maintenance_id
    WHERE asset_id = asset_id_input
    ORDER BY next_due ASC
    LIMIT 1;

    RETURN next_date;
END;
$$ LANGUAGE plpgsql;

select * from next_maintenance_date(1020)