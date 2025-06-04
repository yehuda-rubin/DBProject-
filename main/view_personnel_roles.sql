CREATE VIEW view_personnel_roles AS
SELECT 
    p.personnel_id,
    p.name,
    p.rank,
    p.role,
    o.operation_name,
    o.status
FROM Manages m
JOIN Personnel p ON m.personnel_id = p.personnel_id
JOIN Operations o ON m.operation_id = o.operation_id;

select * from view_personnel_roles;