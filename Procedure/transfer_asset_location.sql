-- Procedure to transfer an asset from one location to another
CREATE OR REPLACE PROCEDURE transfer_asset_location(
    asset_id_input INT,
    new_location_id INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Check if asset already stored
    IF EXISTS (SELECT 1 FROM Stored_at WHERE asset_id = asset_id_input) THEN
        UPDATE Stored_at
        SET location_id = new_location_id
        WHERE asset_id = asset_id_input;
    ELSE
        -- If not stored yet, insert a new record
        INSERT INTO Stored_at(asset_id, location_id)
        VALUES (asset_id_input, new_location_id);
    END IF;

    RAISE NOTICE 'Asset % transferred to location %', asset_id_input, new_location_id;
END;
$$;
