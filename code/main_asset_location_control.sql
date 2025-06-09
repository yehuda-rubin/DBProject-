-- Main Program 1: Call count_assets_in_location() and transfer_asset_location()
DO $$
DECLARE
    c refcursor;
    r RECORD;
    asset_count INT;
BEGIN
    -- Call the function to count assets in location 2020
    asset_count := count_assets_in_location(2020);
    RAISE NOTICE 'Assets in Location 2020: %', asset_count;
    
    -- Call the procedure to transfer asset
    CALL transfer_asset_location(1001, 2021);
    
    -- Check count after transfer
    asset_count := count_assets_in_location(2020);
    RAISE NOTICE 'Assets in Location 2020 after transfer: %', asset_count;
    
    asset_count := count_assets_in_location(2021);
    RAISE NOTICE 'Assets in Location 2021 after transfer: %', asset_count;
END;
$$;

-- Main Program 2: Multiple asset transfers with reporting
DO $$
DECLARE
    asset_cursor CURSOR FOR 
        SELECT asset_id FROM Assets WHERE asset_id BETWEEN 1 AND 5;
    current_asset RECORD;
    location_count INT;
BEGIN
    -- Show initial state
    RAISE NOTICE '=== Initial Asset Distribution ===';
    location_count := count_assets_in_location(2020);
    RAISE NOTICE 'Location 2020: % assets', location_count;
    
    location_count := count_assets_in_location(2021);
    RAISE NOTICE 'Location 2021: % assets', location_count;
    
    location_count := count_assets_in_location(2022);
    RAISE NOTICE 'Location 2022: % assets', location_count;
    
    location_count := count_assets_in_location(2023);
    RAISE NOTICE 'Location 2023: % assets', location_count;
    
    -- Transfer assets
    RAISE NOTICE '=== Transferring Assets ===';
    CALL transfer_asset_location(1002, 2022);
    CALL transfer_asset_location(1003, 2023);
    CALL transfer_asset_location(1005, 2020);
    
    -- Show final state
    RAISE NOTICE '=== Final Asset Distribution ===';
    location_count := count_assets_in_location(2020);
    RAISE NOTICE 'Location 2020: % assets', location_count;
    
    location_count := count_assets_in_location(2021);
    RAISE NOTICE 'Location 2021: % assets', location_count;
    
    location_count := count_assets_in_location(2022);
    RAISE NOTICE 'Location 2022: % assets', location_count;
    
    location_count := count_assets_in_location(2023);
    RAISE NOTICE 'Location 2023: % assets', location_count;
END;
$$;