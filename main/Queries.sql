-- 1. סוג התחמושת שהוזמן הכי הרבה לאחרונה ומי הדרגה שהכי הזמינה אותו
SELECT 
    a.type AS AmmunitionType,
    COUNT(o.id) AS OrdersCount,
    p.Role AS MostFrequentRole
FROM Orders o
JOIN Ammunition a ON o.ammo_id = a.id
JOIN Moved_by mb ON o.id = mb.id_o
JOIN Personnel p ON mb.id_a = a.id
GROUP BY a.type, p.Role
ORDER BY OrdersCount DESC
LIMIT 1;

-- 2. כמה תחמושת יש בכל מחסן
SELECT 
    s.location_name,
    SUM(CAST(a.quantity AS INT)) AS total_quantity
FROM Ammunition a
JOIN StorageLocation s ON a.location_id = s.id
GROUP BY s.location_name;

-- 3. כמה תחמושות אושרו לפי דרגה
SELECT 
    p.Role,
    COUNT(DISTINCT ap.id_a) AS ApprovedCount
FROM Approved ap
JOIN Personnel p ON ap.id_p = p.id
GROUP BY p.Role;

-- 4. סטטוס מיקום נוכחי של כל תחמושת
SELECT 
    a.id AS AmmoID,
    s.location_name AS CurrentLocation
FROM Ammunition a
JOIN StorageLocation s ON a.location_id = s.id;

-- 5. תחמושות שהוזנו לפני אפריל 2025
SELECT id, type, date_added 
FROM Ammunition
WHERE date_added < '2025-04-01';

-- 6. כמה תחמושות נוספו כל יום
SELECT 
    date_added,
    COUNT(*) AS AmmunitionCount
FROM Ammunition
GROUP BY date_added;

-- 7. תחמושות שלא עברו בדיקה או שנכשלו
SELECT a.id, a.type
FROM Ammunition a
LEFT JOIN Inspections i ON a.id = i.ammo_id
WHERE i.status IS NULL OR i.status = 'Failed';

-- 8. השוואת כמות ההזמנות לפי סוג תחמושת
SELECT 
    a.type,
    COUNT(o.id) AS OrdersCount
FROM Orders o
JOIN Ammunition a ON o.ammo_id = a.id
GROUP BY a.type
ORDER BY OrdersCount DESC;

-- 9. מי אחראי על הכי הרבה תחמושת
SELECT p.name, p.Role
FROM Personnel p
JOIN Sorted_in s ON p.id = s.id_p
JOIN Ammunition a ON s.id_a = a.id
GROUP BY p.id, p.name, p.Role
HAVING SUM(CAST(a.quantity AS INT)) = (
  SELECT MAX(total_qty)
  FROM (
    SELECT SUM(CAST(a2.quantity AS INT)) AS total_qty
    FROM Sorted_in s2
    JOIN Ammunition a2 ON s2.id_a = a2.id
    GROUP BY s2.id_p
  ) AS sub
);

-- 10. תחמושות שלא הוזמנו מעולם
SELECT a.id, a.type
FROM Ammunition a
WHERE a.id NOT IN (
  SELECT ammo_id FROM Orders
);

-- 11. כמה תחמושות בכל סוג אחסון
SELECT s.location_type, COUNT(*) AS AmmoCount
FROM StorageLocation s
JOIN Ammunition a ON s.id = a.location_id
GROUP BY s.location_type;

-- 12. תחמושות שזזו יותר מפעם אחת
SELECT a.id, a.type, COUNT(mb.id_im) AS MoveCount
FROM Moved_by mb
JOIN Ammunition a ON mb.id_a = a.id
GROUP BY a.id, a.type
HAVING COUNT(mb.id_im) > 1;

--התחמושת הכי ותיקה שאושרה לבדיקה מוצלחת, כולל שם המאשר והמחסן
SELECT 
    a.type AS Ammunition_Type,
    s.location_name AS Storage_Name,
    p.name AS Approved_By
FROM Ammunition a
JOIN StorageLocation s ON a.location_id = s.id
JOIN Approved ap ON a.id = ap.id_a
JOIN Inspections i ON ap.id_i = i.id
JOIN Personnel p ON ap.id_p = p.id
WHERE i.status = 'Passed'
  AND a.date_add = (
    SELECT MIN(date_add)
    FROM Ammunition a2
    JOIN Approved ap2 ON a2.id = ap2.id_a
    JOIN Inspections i2 ON ap2.id_i = i2.id
    WHERE i2.status = 'Passed'
  );


-- -------------------------
-- UPDATE QUERIES
-- -------------------------

-- עדכון סטטוס של בדיקה
UPDATE Inspections SET status = 'Passed' WHERE id = 2;

-- העברת תחמושת למחסן אחר
UPDATE Ammunition SET location_id = 102 WHERE id = 3;

-- שינוי דרגה של עובד
UPDATE Personnel SET Role = 'Senior Supervisor' WHERE id = 2;

-- -------------------------
-- DELETE QUERIES
-- -------------------------

-- מוחק את השורה הראשונה
DELETE FROM Sorted_in
WHERE (id_p, id_a) IN (
  SELECT id_p, id_a FROM Sorted_in LIMIT 1
);


-- מחיקת כל התחמושות שקושרו לעובד בדרגה מסוימת
DELETE FROM Sorted_in
WHERE id_p IN (
  SELECT id FROM Personnel WHERE Role = 'Sergeant'
);

-- תחמושת ששויכה להזמנה אך לא יצאה
DELETE FROM places
WHERE id_o = (
  SELECT id FROM Orders ORDER BY id DESC LIMIT 1
);
