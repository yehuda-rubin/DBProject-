CREATE VIEW view_asset_locations AS
SELECT 
    a.asset_id,
    a.name AS asset_name,
    l.location_name,
    l.location_type
FROM Assets a
JOIN Stored_at s ON a.asset_id = s.asset_id
JOIN Location l ON s.location_id = l.location_id;

select * FROM view_asset_locations;