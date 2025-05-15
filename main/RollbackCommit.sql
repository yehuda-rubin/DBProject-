BEGIN;

UPDATE Ammunition
SET 
    type = '7.62mm NATO',
    quantity = '950',
    location_id = 101,
    date_added = DATE '2023-03-10'
WHERE id = 400;

SELECT * FROM Ammunition WHERE id = 400;

ROLLBACK;


BEGIN;

UPDATE Ammunition
SET type = '5.56 NATO', quantity = '1200', location_id = 101, date_add = DATE '2023-01-15'
WHERE id = 400;

COMMIT;

