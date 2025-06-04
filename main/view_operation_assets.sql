CREATE VIEW view_operation_assets AS
SELECT 
    o.operation_name,
    a.name AS asset_name,
    a.category,
    a.type
FROM Used_in u
JOIN Operations o ON u.operation_id = o.operation_id
JOIN Assets a ON u.asset_id = a.asset_id;

select * from view_operation_assets;