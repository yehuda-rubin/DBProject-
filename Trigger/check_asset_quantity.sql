-- Trigger function to check asset quantity before inserting a movement
CREATE OR REPLACE FUNCTION check_asset_quantity()
RETURNS TRIGGER AS $$
DECLARE
    available_qty INT;
BEGIN
    SELECT quantity INTO available_qty
    FROM Assets
    WHERE asset_id = NEW.asset_id;

    IF NEW.quantity > available_qty THEN
        RAISE EXCEPTION 'Not enough assets in stock. Requested: %, Available: %',
            NEW.quantity, available_qty;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to enforce the above rule before inserting into Moves
CREATE TRIGGER trg_check_asset_quantity
BEFORE INSERT ON Moves
FOR EACH ROW
EXECUTE FUNCTION check_asset_quantity();
