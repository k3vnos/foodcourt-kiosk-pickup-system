from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_connection

app = Flask(__name__)
CORS(app)  


def dict_from_menu_row(row):
    return {
        "itemid": row[0],
        "vendorid": row[1],
        "name": row[2],
        "description": row[3],
        "price": float(row[4]),
        "isavailable": row[5],
        "category": row[6],
    }


def dict_from_vendor_row(row):
    return {
        "vendorid": row[0],
        "name": row[1],
        "category": row[2],
        "isopen": row[3],
        "avgprepminutes": row[4],
    }



@app.get("/api/menu")
def get_menu():
    """Return all menu items, joined with vendor names."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT m.itemid, m.vendorid, m.name, m.description,
               m.price, m.isavailable, m.category, v.name AS vendor_name
        FROM menuitem m
        JOIN vendor v ON m.vendorid = v.vendorid
        ORDER BY v.name, m.name;
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    items = []
    for r in rows:
        base = dict_from_menu_row(r[:7])
        base["vendor_name"] = r[7]
        items.append(base)
    return jsonify(items)


@app.get("/api/vendors")
def get_vendors():
    """Return vendor list for dropdown."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT vendorid, name, category, isopen, avgprepminutes
        FROM vendor
        ORDER BY name;
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()

    vendors = [dict_from_vendor_row(r) for r in rows]
    return jsonify(vendors)


@app.post("/api/menu/add")
def add_menu_item():
    """Insert a new menu item."""
    data = request.json
    vendor_id = data.get("vendorid")
    name = data.get("name")
    description = data.get("description") or ""
    price = data.get("price")
    category = data.get("category") or None

    if not vendor_id or not name or price is None:
        return jsonify({"error": "vendorid, name and price are required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO menuitem (vendorid, name, description, price, category)
        VALUES (%s, %s, %s, %s, %s)
        RETURNING itemid;
    """, (vendor_id, name, description, price, category))
    new_id = cur.fetchone()[0]
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"message": "Item added", "itemid": new_id})


@app.post("/api/order/update-status")
def update_order_status():
    """Set an order status to READY."""
    data = request.json
    order_id = data.get("orderid")

    if not order_id:
        return jsonify({"error": "orderid is required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE "Order"
        SET status = 'READY'
        WHERE orderid = %s;
    """, (order_id,))
    updated = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()

    if updated == 0:
        return jsonify({"message": "No order found with that ID"}), 404

    return jsonify({"message": f"Order {order_id} marked as READY"})


@app.post("/api/menu/disable")
def disable_menu_item():
    """Logical delete: mark an item as unavailable."""
    data = request.json
    item_id = data.get("itemid")

    if not item_id:
        return jsonify({"error": "itemid is required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE menuitem
        SET isavailable = false
        WHERE itemid = %s;
    """, (item_id,))
    updated = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()

    if updated == 0:
        return jsonify({"message": "No item found with that ID"}), 404

    return jsonify({"message": f"Item {item_id} disabled (IsAvailable = false)"})


@app.get("/api/health")
def health():
    return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(debug=True)
