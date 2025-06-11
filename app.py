from flask import Flask, render_template, request, redirect, jsonify
import psycopg2
from psycopg2 import sql
from connectToPostgres import get_connection
import json
from datetime import datetime
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Military System Functions Information
FUNCTIONS_INFO = [
    {
        "name": "assign_maintenance_task",
        "type": "procedure",
        "params": ["p_personnel_id", "p_maintenance_id"],
        "desc": "Assigns maintenance task to specific personnel / משייכת משימת תחזוקה לחייל מסוים",
        "category": "maintenance"
    },
    {
        "name": "transfer_asset_location",
        "type": "procedure",
        "params": ["asset_id_input", "new_location_id"],
        "desc": "Transfers asset from one location to another / מעבירה נכס ממיקום אחד לאחר",
        "category": "logistics"
    },
    {
        "name": "count_assets_in_location",
        "type": "function",
        "params": ["loc_id"],
        "desc": "Counts assets in specific location / סופרת כמה נכסים נמצאים במיקום מסוים",
        "category": "inventory"
    },
    {
        "name": "next_maintenance_date",
        "type": "function",
        "params": ["asset_id_input"],
        "desc": "Returns next maintenance date for asset / מחזירה את תאריך התחזוקה הבא לנכס",
        "category": "maintenance"
    }
]


def log_database_operation(operation, table_name, user_info=None):
    """Log database operations for audit trail"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    logger.info(f"[{timestamp}] MIMS Operation: {operation} on {table_name}")


@app.route('/')
def index():
    """Main dashboard route"""
    conn = get_connection()
    if not conn:
        logger.error("Database connection failed")
        return render_template("error.html", error="Database connection error")

    cur = conn.cursor()

    try:
        # Get all table names and views
        cur.execute("""
            SELECT table_name, table_type
            FROM information_schema.tables
            WHERE table_schema = 'public'
            ORDER BY table_name
        """)
        raw_tables = cur.fetchall()

        # Get column count for each table
        cur.execute("""
            SELECT table_name, COUNT(*) as column_count
            FROM information_schema.columns
            WHERE table_schema = 'public'
            GROUP BY table_name
        """)
        column_counts = {row[0]: row[1] for row in cur.fetchall()}

        # Separate regular tables and views
        regular_tables = []
        view_tables = []

        for table_name, table_type in raw_tables:
            table_info = {
                'name': table_name,
                'type': table_type,
                'column_count': column_counts.get(table_name, 0)
            }

            if table_type == 'VIEW' or table_name.lower().startswith('view'):
                view_tables.append(table_info)
            else:
                regular_tables.append(table_info)

        # Sort regular tables by column count (descending)
        regular_tables.sort(key=lambda t: -t['column_count'])

        # Combine lists
        all_tables = regular_tables + view_tables
        table_names = [t['name'] for t in all_tables]

        # Get system statistics
        stats = get_system_statistics(cur)

        return render_template("index.html",
                               tables=table_names,
                               functions=FUNCTIONS_INFO,
                               stats=stats)

    except Exception as e:
        logger.error(f"Error in main route: {str(e)}")
        return render_template("error.html", error=str(e))
    finally:
        cur.close()
        conn.close()


def get_system_statistics(cursor):
    """Get system statistics for dashboard"""
    try:
        # Get table count
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        """)
        table_count = cursor.fetchone()[0]

        # Get view count
        cursor.execute("""
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_type = 'VIEW'
        """)
        view_count = cursor.fetchone()[0]

        return {
            'table_count': table_count,
            'view_count': view_count,
            'function_count': len(FUNCTIONS_INFO),
            'system_status': 'OPERATIONAL'
        }
    except Exception as e:
        logger.error(f"Error getting statistics: {str(e)}")
        return {
            'table_count': 0,
            'view_count': 0,
            'function_count': len(FUNCTIONS_INFO),
            'system_status': 'ERROR'
        }


@app.route('/table/<table_name>')
def show_table(table_name):
    """Get table data with enhanced error handling"""
    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("SELECT", table_name)

        # Check if table exists
        cur.execute("""
            SELECT EXISTS (
                SELECT FROM information_schema.tables 
                WHERE table_schema = 'public' AND table_name = %s
            )
        """, [table_name])

        if not cur.fetchone()[0]:
            return jsonify({"error": f"Table '{table_name}' does not exist"})

        # Get table data with limit
        cur.execute(sql.SQL("SELECT * FROM {} LIMIT 1000").format(sql.Identifier(table_name)))
        rows = cur.fetchall()
        colnames = [desc[0] for desc in cur.description]

        return jsonify({
            "columns": colnames,
            "rows": rows,
            "total_rows": len(rows),
            "table_name": table_name
        })

    except Exception as e:
        logger.error(f"Error fetching table {table_name}: {str(e)}")
        return jsonify({"error": f"Database error: {str(e)}"})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/columns')
def get_columns(table_name):
    """Get column information with data types"""
    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT column_name, is_nullable, data_type, 
                   character_maximum_length, column_default
            FROM information_schema.columns
            WHERE table_schema = 'public' AND table_name = %s
            ORDER BY ordinal_position
        """, [table_name])

        cols = cur.fetchall()
        column_info = []

        for name, nullable, data_type, max_length, default in cols:
            column_info.append({
                "name": name,
                "nullable": nullable == 'YES',
                "data_type": data_type,
                "max_length": max_length,
                "default": default
            })

        return jsonify(column_info)

    except Exception as e:
        logger.error(f"Error getting columns for {table_name}: {str(e)}")
        return jsonify({"error": str(e)})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/primary_key')
def get_primary_key(table_name):
    """Get primary key information"""
    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT a.attname
            FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
            WHERE i.indrelid = %s::regclass AND i.indisprimary
        """, [table_name])

        row = cur.fetchone()
        return jsonify({"primary_key": row[0] if row else None})

    except Exception as e:
        logger.error(f"Error getting primary key for {table_name}: {str(e)}")
        return jsonify({"error": str(e)})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/insert', methods=['POST'])
def insert_row(table_name):
    """Insert new row with validation"""
    data = request.get_json()
    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("INSERT", table_name)

        # Filter out empty values
        filtered_data = {k: v for k, v in data.items() if v is not None and v != ''}

        if not filtered_data:
            return jsonify({"error": "No valid data provided"})

        columns = filtered_data.keys()
        values = list(filtered_data.values())

        insert_query = sql.SQL("INSERT INTO {} ({}) VALUES ({})").format(
            sql.Identifier(table_name),
            sql.SQL(', ').join(map(sql.Identifier, columns)),
            sql.SQL(', ').join(sql.Placeholder() * len(values))
        )

        cur.execute(insert_query, values)
        conn.commit()

        logger.info(f"Successfully inserted row into {table_name}")
        return jsonify({"success": True, "message": "Record inserted successfully"})

    except Exception as e:
        conn.rollback()
        logger.error(f"Error inserting into {table_name}: {str(e)}")
        return jsonify({"error": str(e)})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/update', methods=['POST'])
def update_row(table_name):
    """Update existing row with validation"""
    data = request.get_json()
    pk_column = data.get('pk')
    pk_value = data.get('pk_val')
    updates = data.get('updates')

    if not pk_column or pk_value is None or not updates:
        return jsonify({"error": "Missing required parameters"}), 400

    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("UPDATE", table_name)

        # Filter out empty updates
        filtered_updates = {k: v for k, v in updates.items() if v is not None}

        if not filtered_updates:
            return jsonify({"error": "No valid updates provided"})

        set_clause = sql.SQL(', ').join(
            sql.Composed([sql.Identifier(k), sql.SQL(' = '), sql.Placeholder()])
            for k in filtered_updates
        )

        values = list(filtered_updates.values()) + [pk_value]

        update_query = sql.SQL("UPDATE {} SET {} WHERE {} = %s").format(
            sql.Identifier(table_name),
            set_clause,
            sql.Identifier(pk_column)
        )

        cur.execute(update_query, values)

        if cur.rowcount == 0:
            return jsonify({"error": "No rows were updated. Record may not exist."})

        conn.commit()
        logger.info(f"Successfully updated {cur.rowcount} row(s) in {table_name}")
        return jsonify({"success": True, "rows_affected": cur.rowcount})

    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating {table_name}: {str(e)}")
        return jsonify({"error": str(e)})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/delete', methods=['POST'])
def delete_row(table_name):
    """Delete row with enhanced validation"""
    data = request.get_json()
    row_data = data.get('row')

    if not row_data:
        return jsonify({"error": "No row data provided"}), 400

    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("DELETE", table_name)

        # Build WHERE clause with all provided columns for safety
        where_conditions = []
        values = []

        for key, value in row_data.items():
            if value is not None:
                where_conditions.append(sql.Composed([
                    sql.Identifier(key),
                    sql.SQL(' = ' if value is not None else ' IS '),
                    sql.Placeholder() if value is not None else sql.SQL('NULL')
                ]))
                if value is not None:
                    values.append(value)

        if not where_conditions:
            return jsonify({"error": "No valid conditions for deletion"}), 400

        where_clause = sql.SQL(' AND ').join(where_conditions)
        delete_query = sql.SQL("DELETE FROM {} WHERE {}").format(
            sql.Identifier(table_name),
            where_clause
        )

        cur.execute(delete_query, values)

        if cur.rowcount == 0:
            return jsonify({"error": "No rows were deleted. Record may not exist."})

        conn.commit()
        logger.info(f"Successfully deleted {cur.rowcount} row(s) from {table_name}")
        return jsonify({"success": True, "rows_affected": cur.rowcount})

    except Exception as e:
        conn.rollback()
        logger.error(f"Error deleting from {table_name}: {str(e)}")
        return jsonify({"error": str(e)})
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/delete_by_criteria', methods=['POST'])
def delete_by_criteria(table_name):
    """Delete multiple rows by criteria"""
    data = request.get_json()
    criteria = data.get('criteria', [])

    if not criteria:
        return jsonify({"error": "No criteria provided"}), 400

    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("DELETE_BY_CRITERIA", table_name)

        # Build WHERE clause from criteria
        where_conditions = []
        values = []

        for criterion in criteria:
            column = criterion.get('column')
            operator = criterion.get('operator', '=')
            value = criterion.get('value')

            if column and value is not None and str(value).strip() != '':
                if operator == 'LIKE':
                    where_conditions.append(sql.Composed([
                        sql.Identifier(column),
                        sql.SQL(' LIKE '),
                        sql.Placeholder()
                    ]))
                    values.append(f"%{value}%")
                elif operator in ['=', '!=', '>', '<', '>=', '<=']:
                    where_conditions.append(sql.Composed([
                        sql.Identifier(column),
                        sql.SQL(f' {operator} '),
                        sql.Placeholder()
                    ]))
                    values.append(value)

        if not where_conditions:
            return jsonify({"error": "No valid conditions provided"}), 400

        # First, count how many rows will be deleted
        count_query = sql.SQL("SELECT COUNT(*) FROM {} WHERE {}").format(
            sql.Identifier(table_name),
            sql.SQL(' AND ').join(where_conditions)
        )
        cur.execute(count_query, values)
        count_to_delete = cur.fetchone()[0]

        logger.info(f"Found {count_to_delete} rows matching deletion criteria in {table_name}")

        if count_to_delete == 0:
            return jsonify({"success": True, "message": "No rows match the criteria", "rows_affected": 0})

        # Execute deletion
        where_clause = sql.SQL(' AND ').join(where_conditions)
        delete_query = sql.SQL("DELETE FROM {} WHERE {}").format(
            sql.Identifier(table_name),
            where_clause
        )

        cur.execute(delete_query, values)
        conn.commit()

        logger.info(f"Successfully deleted {cur.rowcount} row(s) from {table_name} by criteria")
        return jsonify({
            "success": True,
            "rows_affected": cur.rowcount,
            "message": f"Successfully deleted {cur.rowcount} rows matching criteria"
        })

    except Exception as e:
        conn.rollback()
        logger.error(f"Error deleting by criteria from {table_name}: {str(e)}")
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        cur.close()
        conn.close()


@app.route('/table/<table_name>/update_by_criteria', methods=['POST'])
def update_by_criteria(table_name):
    """Update multiple rows by criteria"""
    data = request.get_json()
    criteria = data.get('criteria', [])
    updates = data.get('updates', {})

    if not criteria or not updates:
        return jsonify({"error": "Both criteria and updates are required"}), 400

    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation("UPDATE_BY_CRITERIA", table_name)

        # Build WHERE clause from criteria
        where_conditions = []
        where_values = []

        for criterion in criteria:
            column = criterion.get('column')
            operator = criterion.get('operator', '=')
            value = criterion.get('value')

            if column and value is not None and str(value).strip() != '':
                if operator == 'LIKE':
                    where_conditions.append(sql.Composed([
                        sql.Identifier(column),
                        sql.SQL(' LIKE '),
                        sql.Placeholder()
                    ]))
                    where_values.append(f"%{value}%")
                elif operator in ['=', '!=', '>', '<', '>=', '<=']:
                    where_conditions.append(sql.Composed([
                        sql.Identifier(column),
                        sql.SQL(f' {operator} '),
                        sql.Placeholder()
                    ]))
                    where_values.append(value)

        # Build SET clause from updates
        set_conditions = []
        set_values = []

        for column, value in updates.items():
            if column and value is not None and str(value).strip() != '':
                set_conditions.append(sql.Composed([
                    sql.Identifier(column),
                    sql.SQL(' = '),
                    sql.Placeholder()
                ]))
                set_values.append(value)

        if not where_conditions or not set_conditions:
            return jsonify({"error": "No valid conditions or updates provided"}), 400

        # First, count how many rows will be updated
        count_query = sql.SQL("SELECT COUNT(*) FROM {} WHERE {}").format(
            sql.Identifier(table_name),
            sql.SQL(' AND ').join(where_conditions)
        )
        cur.execute(count_query, where_values)
        count_to_update = cur.fetchone()[0]

        logger.info(f"Found {count_to_update} rows matching update criteria in {table_name}")

        if count_to_update == 0:
            return jsonify({"success": True, "message": "No rows match the criteria", "rows_affected": 0})

        # Execute update
        all_values = set_values + where_values
        update_query = sql.SQL("UPDATE {} SET {} WHERE {}").format(
            sql.Identifier(table_name),
            sql.SQL(', ').join(set_conditions),
            sql.SQL(' AND ').join(where_conditions)
        )

        cur.execute(update_query, all_values)
        conn.commit()

        logger.info(f"Successfully updated {cur.rowcount} row(s) in {table_name} by criteria")
        return jsonify({
            "success": True,
            "rows_affected": cur.rowcount,
            "message": f"Successfully updated {cur.rowcount} rows matching criteria"
        })

    except Exception as e:
        conn.rollback()
        logger.error(f"Error updating by criteria in {table_name}: {str(e)}")
        return jsonify({"error": f"Database error: {str(e)}"}), 500
    finally:
        cur.close()
        conn.close()


@app.route('/call_function', methods=['POST'])
def call_function():
    """Execute database function or procedure with enhanced handling"""
    try:
        if request.content_type == 'application/json':
            data = request.get_json()
        else:
            data = json.loads(request.data)
    except Exception as e:
        return jsonify({"error": "Invalid JSON format"}), 400

    name = data.get('name')
    routine_type = data.get('type')
    params = data.get('params', {})

    if not name or not routine_type:
        return jsonify({"error": "Missing function name or type"}), 400

    conn = get_connection()
    if not conn:
        return jsonify({"error": "Database connection error"})

    cur = conn.cursor()
    try:
        log_database_operation(f"CALL_{routine_type.upper()}", name)

        # Prepare parameters
        param_values = list(params.values()) if params else []
        placeholders = ', '.join(['%s'] * len(param_values))

        if routine_type.lower() == 'function':
            query = f"SELECT * FROM {name}({placeholders})"
            cur.execute(query, param_values)
            result = cur.fetchall()
            columns = [desc[0] for desc in cur.description] if cur.description else []

            logger.info(f"Successfully executed function {name}")
            return jsonify({
                "result": result,
                "columns": columns,
                "row_count": len(result),
                "execution_time": datetime.now().isoformat()
            })

        elif routine_type.lower() == 'procedure':
            query = f"CALL {name}({placeholders})"
            cur.execute(query, param_values)
            conn.commit()

            logger.info(f"Successfully executed procedure {name}")
            return jsonify({
                "message": f"Procedure '{name}' executed successfully",
                "execution_time": datetime.now().isoformat()
            })
        else:
            return jsonify({"error": f"Unknown routine type: {routine_type}"}), 400

    except Exception as e:
        conn.rollback()
        logger.error(f"Error executing {routine_type} {name}: {str(e)}")
        return jsonify({"error": str(e)}), 500
    finally:
        cur.close()
        conn.close()


@app.route('/system/status')
def system_status():
    """Get system status information"""
    conn = get_connection()
    if not conn:
        return jsonify({"status": "ERROR", "message": "Database connection failed"})

    try:
        cur = conn.cursor()
        stats = get_system_statistics(cur)

        return jsonify({
            "status": "OPERATIONAL",
            "timestamp": datetime.now().isoformat(),
            "statistics": stats,
            "version": "MIMS v1.0"
        })
    except Exception as e:
        return jsonify({"status": "ERROR", "message": str(e)})
    finally:
        conn.close()


@app.errorhandler(404)
def not_found_error(error):
    return jsonify({"error": "Resource not found"}), 404


@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({"error": "Internal server error"}), 500


if __name__ == '__main__':
    logger.info("Starting MIMS - Military Integrated Management System")
    app.run(debug=True, port=5000, host='0.0.0.0')