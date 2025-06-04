-- =============================
-- שלב 1: שינוי שמות טבלאות קיימות
-- =============================

-- נשמר השם Personnel (אין שינוי)
ALTER TABLE StorageLocation RENAME TO Location;
ALTER TABLE Ammunition RENAME TO Assets;
ALTER TABLE InventoryMovement RENAME TO Movement;
ALTER TABLE Orders RENAME TO Operations;

-- =============================
-- שלב 2: שינוי שמות עמודות קיימות
-- =============================

-- Location
ALTER TABLE Location RENAME COLUMN id TO location_id;

-- Assets
ALTER TABLE Assets RENAME COLUMN id TO asset_id;
ALTER TABLE Assets RENAME COLUMN date_added TO purchase_date;
-- העמודה location_id תטופל בטבלת קישור

-- Personnel_
ALTER TABLE Personnel RENAME COLUMN id TO personnel_id;

-- Movement
ALTER TABLE Movement RENAME COLUMN id TO movement_id;
ALTER TABLE Movement RENAME COLUMN inspention_date TO movement_date;

-- Operations
ALTER TABLE Operations RENAME COLUMN id TO operation_id;
ALTER TABLE Operations RENAME COLUMN ammo_id TO asset_id;
ALTER TABLE Operations RENAME COLUMN to_movement_id TO to_location_id;

-- =============================
-- שלב 3: הוספת עמודות חסרות
-- =============================

-- Assets
ALTER TABLE Assets ADD COLUMN name VARCHAR(50);
ALTER TABLE Assets ADD COLUMN category VARCHAR(50);
ALTER TABLE Assets ADD COLUMN description VARCHAR(1000);
ALTER TABLE Assets ADD COLUMN warranty_expiration DATE;

-- Location
ALTER TABLE Location ADD COLUMN capacity INT;

-- Personnel_
ALTER TABLE Personnel ADD COLUMN rank VARCHAR(50);

-- Movement
ALTER TABLE Movement ADD COLUMN quantity INT;
ALTER TABLE Movement ADD COLUMN from_location VARCHAR(50);
ALTER TABLE Movement ADD COLUMN to_location VARCHAR(50);

-- =============================
-- שלב 4: יצירת טבלאות קשרים חדשות
-- =============================

CREATE TABLE IF NOT EXISTS Authorized_by (
  movement_id INT NOT NULL,
  personnel_id INT NOT NULL,
  PRIMARY KEY (movement_id),
  FOREIGN KEY (movement_id) REFERENCES Movement(movement_id),
  FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id)
);

CREATE TABLE IF NOT EXISTS Moves (
  movement_id INT NOT NULL,
  asset_id INT NOT NULL,
  PRIMARY KEY (asset_id),
  FOREIGN KEY (movement_id) REFERENCES Movement(movement_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

CREATE TABLE IF NOT EXISTS Responsible (
  asset_id INT NOT NULL,
  personnel_id INT NOT NULL,
  PRIMARY KEY (personnel_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id),
  FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id)
);

CREATE TABLE IF NOT EXISTS Requires (
  maintenance_id INT NOT NULL,
  asset_id INT NOT NULL,
  PRIMARY KEY (asset_id),
  FOREIGN KEY (maintenance_id) REFERENCES Maintenance(maintenance_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

CREATE TABLE IF NOT EXISTS Performs (
  personnel_id INT NOT NULL,
  maintenance_id INT NOT NULL,
  PRIMARY KEY (personnel_id),
  FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id),
  FOREIGN KEY (maintenance_id) REFERENCES Maintenance(maintenance_id)
);

CREATE TABLE IF NOT EXISTS Stored_at (
  location_id INT NOT NULL,
  asset_id INT NOT NULL,
  PRIMARY KEY (asset_id),
  FOREIGN KEY (location_id) REFERENCES Location(location_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

CREATE TABLE IF NOT EXISTS Used_in (
  asset_id INT NOT NULL,
  operation_id INT NOT NULL,
  PRIMARY KEY (asset_id, operation_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id),
  FOREIGN KEY (operation_id) REFERENCES Operations_(operation_id)
);

CREATE TABLE IF NOT EXISTS Manages (
  personnel_id INT NOT NULL,
  operation_id INT NOT NULL,
  PRIMARY KEY (personnel_id),
  FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id),
  FOREIGN KEY (operation_id) REFERENCES Operations_(operation_id)
);

-- =============================
-- שלב 5: יצירת טבלאות יש מאין
-- =============================

CREATE TABLE IF NOT EXISTS Maintenance (
  maintenance_id INT PRIMARY KEY,
  cost_of_repair INT NOT NULL,
  description VARCHAR(1000) NOT NULL,
  next_due DATE NOT NULL,
  performed_on DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS Operations_ (
  operation_id INT PRIMARY KEY,
  objective VARCHAR(100) NOT NULL,
  end_date DATE NOT NULL,
  start_date DATE NOT NULL,
  status INT NOT NULL,
  type ENUM('mission', 'order', 'inspection', 'training') NOT NULL,
  operation_name ENUM('planned', 'in_progress', 'completed', 'cancelled') NOT NULL
);


-- =============================
-- שלב 6: שדרוג טבלאות קשרים קיימות
-- =============================

-- Sorted_in ⟶ Stored_at
-- נשמר הקשר בין Asset למיקום, דרך אחראי
CREATE TABLE IF NOT EXISTS Stored_at (
  location_id INT NOT NULL,
  asset_id INT NOT NULL,
  PRIMARY KEY (asset_id),
  FOREIGN KEY (location_id) REFERENCES Location(location_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

INSERT INTO Stored_at (location_id, asset_id)
SELECT id_sl, id_a FROM Sorted_in;

-- Moved_by ⟶ Moves
-- קשר בין תנועה לנכס
CREATE TABLE IF NOT EXISTS Moves (
  movement_id INT NOT NULL,
  asset_id INT NOT NULL,
  PRIMARY KEY (asset_id),
  FOREIGN KEY (movement_id) REFERENCES Movement(movement_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id)
);

INSERT INTO Moves (movement_id, asset_id)
SELECT id_im, id_a FROM Moved_by;

-- Approved ⟶ Authorized_by
CREATE TABLE IF NOT EXISTS Authorized_by (
  movement_id INT NOT NULL,
  personnel_id INT NOT NULL,
  PRIMARY KEY (movement_id),
  FOREIGN KEY (movement_id) REFERENCES Movement(movement_id),
  FOREIGN KEY (personnel_id) REFERENCES Personnel(personnel_id)
);

INSERT INTO Authorized_by (movement_id, personnel_id)
SELECT id_i, id_p FROM Approved;

-- places ⟶ Used_in
CREATE TABLE IF NOT EXISTS Used_in (
  asset_id INT NOT NULL,
  operation_id INT NOT NULL,
  PRIMARY KEY (asset_id, operation_id),
  FOREIGN KEY (asset_id) REFERENCES Assets(asset_id),
  FOREIGN KEY (operation_id) REFERENCES Operations(operation_id)
);

INSERT INTO Used_in (asset_id, operation_id)
SELECT id_a, id_o FROM places;
