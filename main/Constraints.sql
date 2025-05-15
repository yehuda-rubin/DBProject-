-- NOT NULL Constraints
ALTER TABLE Orders ALTER COLUMN ammo_id SET NOT NULL;
ALTER TABLE Ammunition ALTER COLUMN type SET NOT NULL;
ALTER TABLE Personnel ALTER COLUMN name SET NOT NULL;

-- CHECK Constraints
ALTER TABLE Ammunition ADD CONSTRAINT check_quantity_positive CHECK (CAST(quantity AS INT) > 0);
ALTER TABLE Ammunition ADD CONSTRAINT check_quantity_limit CHECK (CAST(quantity AS INT) < 10000);


-- DEFAULT Constraints
ALTER TABLE Personnel ALTER COLUMN Role SET DEFAULT 'Worker';
ALTER TABLE Ammunition ALTER COLUMN date_added SET DEFAULT CURRENT_DATE;
