import random
from datetime import datetime, timedelta

NUM_ROWS = 400

def generate_inventory_movement_sql(filename, num_rows):
    with open(filename, mode='w') as file:
        for i in range(1, num_rows + 1):
            ammo_id = random.randint(1, num_rows)
            inspention_date = (datetime.today() - timedelta(days=random.randint(0, 3650))).strftime('%Y-%m-%d')
            file.write(f"INSERT INTO InventoryMovement (ammo_id, inspention_date, id) VALUES ({ammo_id}, '{inspention_date}', {i});\n")

def generate_moved_by_sql(filename, num_rows, max_id=400):
    used_keys = set()
    with open(filename, mode='w') as file:
        while len(used_keys) < num_rows:
            id_a = random.randint(1, max_id)
            id_im = random.randint(1, max_id)
            id_o = random.randint(1, max_id)
            key = (id_a, id_im, id_o)
            if key not in used_keys:
                used_keys.add(key)
                file.write(f"INSERT INTO Moved_by (id_a, id_im, id_o) VALUES ({id_a}, {id_im}, {id_o});\n")

# הרצה
generate_inventory_movement_sql('insert_inventory_movement.sql', NUM_ROWS)
generate_moved_by_sql('insert_moved_by.sql', NUM_ROWS)
