-- Function to count how many assets are stored at a given location
CREATE OR REPLACE FUNCTION count_assets_in_location(loc_id INT)
RETURNS INT AS $$
DECLARE
    asset_count INT;
BEGIN
    SELECT COUNT(*) INTO asset_count
    FROM Stored_at
    WHERE location_id = loc_id;

    RETURN asset_count;
END;
$$ LANGUAGE plpgsql;

select * from count_assets_in_location(2020);