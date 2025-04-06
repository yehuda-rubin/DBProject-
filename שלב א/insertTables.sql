-- Ammunition Table
INSERT INTO Ammunition (id, type, location_id, quantity, date_add)
VALUES
(1, 'Type A', 101, '1000', '2025-04-06'),
(2, 'Type B', 102, '500', '2025-04-06'),
(3, 'Type C', 103, '200', '2025-04-06');

-- InventoryMovement Table
INSERT INTO InventoryMovement (ammo_id, inspention_date, id)
VALUES
(1, '2025-04-06', 1),
(2, '2025-04-07', 2),
(3, '2025-04-08', 3);

-- Orders Table
INSERT INTO Orders (id, ammo_id, from_Location_id, to_movement_id)
VALUES
(1, 1, 101, 1),
(2, 2, 102, 2),
(3, 3, 103, 3);

-- StorageLocation Table
INSERT INTO StorageLocation (location_name, location_type, id)
VALUES
('Warehouse A', 'Main Storage', 101),
('Warehouse B', 'Backup Storage', 102),
('Warehouse C', 'Reserved Storage', 103);

-- Personnel Table
INSERT INTO Personnel (id, name, email, phone_number, Role)
VALUES
(1, 'John Doe', 'john.doe@example.com', 123456789, 'Manager'),
(2, 'Jane Smith', 'jane.smith@example.com', 987654321, 'Supervisor'),
(3, 'Mike Johnson', 'mike.johnson@example.com', 112233445, 'Worker');

-- Inspections Table
INSERT INTO Inspections (ammo_id, inspection_Date, id, status)
VALUES
(1, '2025-04-06', 1, 'Passed'),
(2, '2025-04-07', 2, 'Failed'),
(3, '2025-04-08', 3, 'Passed');

-- Sorted_in Table
INSERT INTO Sorted_in (id_sl, id_p, id_a)
VALUES
(101, 1, 1),
(102, 2, 2),
(103, 3, 3);

-- Moved_by Table
INSERT INTO Moved_by (id_a, id_im, id_o)
VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 3);

-- Approved Table
INSERT INTO Approved (id_p, id_i, id_a)
VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 3);

-- places Table
INSERT INTO places (id_o, id_a)
VALUES
(1, 1),
(2, 2),
(3, 3);
