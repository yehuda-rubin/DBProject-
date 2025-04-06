CREATE TABLE Ammunition
(
  id INT NOT NULL,
  type varchar NOT NULL,
  location_id INT NOT NULL,
  quantity varchar(50) NOT NULL,
  date_add DATE NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE InventoryMovement
(
  ammo_id INT NOT NULL,
  inspention_date DATE NOT NULL,
  id INT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Orders
(
  id INT NOT NULL,
  ammo_id INT NOT NULL,
  from_Location_id INT NOT NULL,
  to_movement_id INT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE StorageLocation
(
  location_name varchar(50) NOT NULL,
  location_type varchar(50) NOT NULL,
  id INT NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Personnel
(
  id INT NOT NULL,
  name varchar(50) NOT NULL,
  email varchar(50) NOT NULL,
  phone_number INT NOT NULL,
  Role varchar(50) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Inspections
(
  ammo_id INT NOT NULL,
  inspection_Date date NOT NULL,
  id INT NOT NULL,
  status varchar(50) NOT NULL,
  PRIMARY KEY (id)
);

CREATE TABLE Sorted_in
(
  id_sl INT NOT NULL,
  id_p INT NOT NULL,
  id_a INT NOT NULL,
  PRIMARY KEY (id_p, id_a),
  FOREIGN KEY (id_sl) REFERENCES StorageLocation(id),
  FOREIGN KEY (id_p) REFERENCES Personnel(id),
  FOREIGN KEY (id_a) REFERENCES Ammunition(id)
);

CREATE TABLE Moved_by
(
  id_a INT NOT NULL,
  id_im INT NOT NULL,
  id_o INT NOT NULL,
  PRIMARY KEY (id_a, id_im, id_o),
  FOREIGN KEY (id_im) REFERENCES InventoryMovement(id),
  FOREIGN KEY (id_a) REFERENCES Ammunition(id),
  FOREIGN KEY (id_o) REFERENCES Orders(id)
);

CREATE TABLE Approved
(
  id_p INT NOT NULL,
  id_i INT NOT NULL,
  id_a INT NOT NULL,
  PRIMARY KEY (id_p, id_i),
  FOREIGN KEY (id_a) REFERENCES Ammunition(id),
  FOREIGN KEY (id_p) REFERENCES Personnel(id),
  FOREIGN KEY (id_i) REFERENCES Inspections(id)
);

CREATE TABLE places
(
  id_o INT NOT NULL,
  id_a INT NOT NULL,
  PRIMARY KEY (id_o, id_a),
  FOREIGN KEY (id_a) REFERENCES Ammunition(id),
  FOREIGN KEY (id_o) REFERENCES Orders(id)
);