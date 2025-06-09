-- Interactive Maintenance Management Program
-- ==========================================

-- Main Menu Program
DO $$
DECLARE
    user_choice INTEGER;
    asset_id_input INTEGER;
    personnel_id_input INTEGER;
    maintenance_id_input INTEGER;
    next_date DATE;
    r RECORD;
BEGIN
    RAISE NOTICE '=== Maintenance Management System ===';
    RAISE NOTICE '1. Check next maintenance date for specific asset';
    RAISE NOTICE '2. Assign maintenance task to personnel';
    RAISE NOTICE '3. Check all assets maintenance dates';
    RAISE NOTICE '4. Show all assigned tasks';
    RAISE NOTICE '=====================================';
    
    -- For demonstration, we'll simulate different choices
    -- In real implementation, you would get user input
    
    -- Option 1: Check specific asset
    RAISE NOTICE 'Example 1: Checking maintenance for asset 1020';
    asset_id_input := 1020;
    SELECT next_maintenance_date(asset_id_input) INTO next_date;
    
    IF next_date IS NOT NULL THEN
        RAISE NOTICE 'Asset ID: %, Next Maintenance Date: %', asset_id_input, next_date;
    ELSE
        RAISE NOTICE 'No maintenance scheduled for asset %', asset_id_input;
    END IF;
    
    -- Option 2: Assign task
    RAISE NOTICE '';
    RAISE NOTICE 'Example 2: Assigning maintenance task';
    personnel_id_input := 1;
    maintenance_id_input := 3003;
    
    BEGIN
        CALL assign_maintenance_task(personnel_id_input, maintenance_id_input);
        RAISE NOTICE 'Task % assigned to personnel %', maintenance_id_input, personnel_id_input;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Failed to assign task: %', SQLERRM;
    END;
    
    -- Option 3: Check multiple assets
    RAISE NOTICE '';
    RAISE NOTICE 'Example 3: Checking maintenance for multiple assets';
    FOR asset_id_input IN 1020..1025 LOOP
        SELECT next_maintenance_date(asset_id_input) INTO next_date;
        
        IF next_date IS NOT NULL THEN
            RAISE NOTICE 'Asset ID: %, Next Maintenance: %', asset_id_input, next_date;
        END IF;
    END LOOP;
    
    -- Option 4: Show assigned tasks
    RAISE NOTICE '';
    RAISE NOTICE 'Example 4: Current assigned tasks';
    FOR r IN 
        SELECT DISTINCT p.personnel_id, p.maintenance_id, m.next_due
        FROM Performs p
        JOIN Maintenance m ON p.maintenance_id = m.maintenance_id
        ORDER BY p.personnel_id, m.next_due
        LIMIT 10
    LOOP
        RAISE NOTICE 'Personnel: %, Maintenance ID: %, Due Date: %', 
                     r.personnel_id, r.maintenance_id, r.next_due;
    END LOOP;
    
    RAISE NOTICE '';
    RAISE NOTICE 'Program completed successfully!';
END;
$$;
