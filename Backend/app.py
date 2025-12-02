from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_connection

app = Flask(__name__)
CORS(app)


# ---------- Helpers ----------

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


def dict_from_order_row(row):
    # Shared order row mapping used for lists
    return {
        "orderid": row[0],
        "customer_name": row[1],
        "customer_email": row[2],
        "vendor_name": row[3],
        "status": row[4],
        "totalamount": float(row[5]),
        "placedat": row[6].isoformat() if row[6] is not None else None,
    }


# ---------- Menu & Vendor endpoints ----------


@app.get("/api/menu")
def get_menu():
    """Return all menu items with vendor names."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT m.itemid,
               m.vendorid,
               m.name,
               m.description,
               m.price,
               m.isavailable,
               m.category,
               v.name AS vendor_name
        FROM menuitem m
        JOIN vendor v ON m.vendorid = v.vendorid
        ORDER BY v.name, m.name;
        """
    )
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
    """Return vendor list for dropdowns."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT vendorid, name, category, isopen, avgprepminutes
        FROM vendor
        ORDER BY name;
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    vendors = [dict_from_vendor_row(r) for r in rows]
    return jsonify(vendors)


@app.post("/api/menu/add")
def add_menu_item():
    """Insert a new menu item."""
    data = request.json or {}
    vendor_id = data.get("vendorid")
    name = data.get("name")
    description = data.get("description") or ""
    price = data.get("price")
    category = data.get("category") or None

    if not vendor_id or not name or price is None:
        return jsonify({"error": "vendorid, name and price are required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            INSERT INTO menuitem (vendorid, name, description, price, category)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING itemid;
            """,
            (vendor_id, name, description, price, category),
        )
        new_id = cur.fetchone()[0]
        conn.commit()
    except Exception as e:
        conn.rollback()
        print("Error inserting menu item:", e)
        return jsonify({"error": "Failed to insert menu item"}), 500
    finally:
        cur.close()
        conn.close()

    return jsonify({"message": "Item added", "itemid": new_id})


@app.post("/api/menu/disable")
def disable_menu_item():
    """Logical delete: mark an item as unavailable."""
    data = request.json or {}
    item_id = data.get("itemid")

    if not item_id:
        return jsonify({"error": "itemid is required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            UPDATE menuitem
            SET isavailable = false
            WHERE itemid = %s;
            """,
            (item_id,),
        )
        updated = cur.rowcount
        conn.commit()
    except Exception as e:
        conn.rollback()
        print("Error disabling menu item:", e)
        return jsonify({"error": "Failed to update menu item"}), 500
    finally:
        cur.close()
        conn.close()

    if updated == 0:
        return jsonify({"message": "No item found with that ID"}), 404

    return jsonify({"message": f"Item {item_id} disabled (IsAvailable = false)"})



@app.post("/api/menu/enable")
def enable_menu_item():
    """Re-enable a previously disabled (unavailable) menu item."""
    data = request.json
    item_id = data.get("itemid")

    if not item_id:
        return jsonify({"error": "itemid is required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE menuitem
        SET isavailable = TRUE
        WHERE itemid = %s;
    """, (item_id,))
    updated = cur.rowcount
    conn.commit()
    cur.close()
    conn.close()

    if updated == 0:
        return jsonify({"message": "No item found with that ID"}), 404

    return jsonify({"message": f"Item {item_id} enabled (IsAvailable = TRUE)"})

# ---------- Order placement (customer) ----------


@app.post("/api/orders")
def place_order():
    """
    Customer-facing endpoint to place an order.

    Expected JSON:
    {
      "customer": { "name": "...", "email": "...", "phone": "..." },
      "vendorid": 1,
      "items": [
        { "itemid": 1, "quantity": 2 },
        ...
      ]
    }
    """
    data = request.json or {}
    customer = data.get("customer") or {}
    vendor_id = data.get("vendorid")
    items = data.get("items") or []

    if not vendor_id or not items:
        return jsonify({"error": "vendorid and items are required"}), 400

    # basic validation
    item_ids = [i.get("itemid") for i in items if i.get("itemid") is not None]
    quantities = {i["itemid"]: int(i.get("quantity", 1)) for i in items if i.get("itemid")}

    if not item_ids:
        return jsonify({"error": "at least one valid itemid is required"}), 400

    conn = get_connection()
    cur = conn.cursor()

    try:
        # 1) Find or create user
        user_id = None
        name = customer.get("name")
        email = customer.get("email")
        phone = customer.get("phone")

        if email:
            cur.execute('SELECT userid FROM "User" WHERE email = %s;', (email,))
            row = cur.fetchone()
            if row:
                user_id = row[0]
            else:
                cur.execute(
                    'INSERT INTO "User"(name, email, phone, passwordhash) '
                    'VALUES (%s, %s, %s, NULL) RETURNING userid;',
                    (name or "Guest", email, phone),
                )
                user_id = cur.fetchone()[0]
        elif name:
            # guest with only a name
            cur.execute(
                'INSERT INTO "User"(name, email, phone, passwordhash) '
                'VALUES (%s, NULL, %s, NULL) RETURNING userid;',
                (name, phone),
            )
            user_id = cur.fetchone()[0]
        # else: completely anonymous guest -> user_id stays None

        # 2) Fetch item prices & availability
        cur.execute(
            """
            SELECT itemid, price, isavailable, vendorid
            FROM menuitem
            WHERE itemid = ANY(%s);
            """,
            (item_ids,),
        )
        rows = cur.fetchall()
        if not rows:
            return jsonify({"error": "No matching menu items found"}), 400

        total = 0.0
        for (itemid, price, isavailable, item_vendor) in rows:
            if not isavailable:
                raise ValueError(f"Item {itemid} is not available.")
            if item_vendor != vendor_id:
                raise ValueError("All items in an order must belong to the same vendor.")
            qty = quantities.get(itemid, 1)
            total += float(price) * qty

        if total <= 0:
            return jsonify({"error": "Total amount must be > 0"}), 400

        # 3) Insert Order
        cur.execute(
            """
            INSERT INTO "Order" (userid, vendorid, kioskid, channel, status, totalamount)
            VALUES (%s, %s, NULL, 'WEB', 'RECEIVED', %s)
            RETURNING orderid;
            """,
            (user_id, vendor_id, total),
        )
        order_id = cur.fetchone()[0]

        # 4) Insert OrderItems
        for (itemid, price, _isavail, _vendor) in rows:
            qty = quantities.get(itemid, 1)
            cur.execute(
                """
                INSERT INTO orderitem (orderid, itemid, quantity, unitprice)
                VALUES (%s, %s, %s, %s);
                """,
                (order_id, itemid, qty, price),
            )

        conn.commit()

        return jsonify(
            {
                "message": "Order placed successfully.",
                "orderid": order_id,
                "total": round(total, 2),
            }
        )
    except ValueError as ve:
        conn.rollback()
        return jsonify({"error": str(ve)}), 400
    except Exception as e:
        conn.rollback()
        print("Error placing order:", e)
        return jsonify({"error": "Internal server error while placing order"}), 500
    finally:
        cur.close()
        conn.close()


# ---------- Orders for admin dashboard ----------


@app.get("/api/orders/pending")
def get_pending_orders():
    """
    Return orders that are not yet completed.
    We'll treat RECEIVED and PREPARING as 'pending'.
    """
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT o.orderid,
               COALESCE(u.name, 'Guest') AS customer_name,
               u.email,
               v.name AS vendor_name,
               o.status,
               o.totalamount,
               o.placedat
        FROM "Order" o
        LEFT JOIN "User" u ON o.userid = u.userid
        JOIN vendor v ON o.vendorid = v.vendorid
        WHERE o.status IN ('RECEIVED', 'PREPARING')
        ORDER BY o.placedat DESC;
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    orders = [dict_from_order_row(r) for r in rows]
    return jsonify(orders)


@app.get("/api/orders/completed")
def get_completed_orders():
    """Return orders that are READY or PICKED_UP or CANCELLED."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT o.orderid,
               COALESCE(u.name, 'Guest') AS customer_name,
               u.email,
               v.name AS vendor_name,
               o.status,
               o.totalamount,
               o.placedat
        FROM "Order" o
        LEFT JOIN "User" u ON o.userid = u.userid
        JOIN vendor v ON o.vendorid = v.vendorid
        WHERE o.status IN ('READY', 'PICKED_UP', 'CANCELLED')
        ORDER BY o.placedat DESC;
        """
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    orders = [dict_from_order_row(r) for r in rows]
    return jsonify(orders)


@app.post("/api/order/update")
def update_order_status_generic():
    """
    Update order status to any allowed value.
    Payload:
    { "orderid": 1, "status": "READY" }
    """
    data = request.json or {}
    order_id = data.get("orderid")
    new_status = data.get("status")

    allowed = {"RECEIVED", "PREPARING", "READY", "PICKED_UP", "CANCELLED"}
    if not order_id or new_status not in allowed:
        return jsonify({"error": "orderid and valid status are required"}), 400

    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(
            """
            UPDATE "Order"
            SET status = %s
            WHERE orderid = %s;
            """,
            (new_status, order_id),
        )
        updated = cur.rowcount
        conn.commit()
    except Exception as e:
        conn.rollback()
        print("Error updating order status:", e)
        return jsonify({"error": "Failed to update order status"}), 500
    finally:
        cur.close()
        conn.close()

    if updated == 0:
        return jsonify({"message": "No order found with that ID"}), 404

    return jsonify({"message": f"Order {order_id} updated to {new_status}."})


@app.get("/api/order/<int:order_id>")
def get_order_details(order_id: int):
    """Return details for a single order (admin view)."""
    conn = get_connection()
    cur = conn.cursor()

    # basic info
    cur.execute(
        """
        SELECT o.orderid,
               COALESCE(u.name, 'Guest'),
               u.email,
               u.phone,
               v.name AS vendor_name,
               o.status,
               o.totalamount,
               o.placedat
        FROM "Order" o
        LEFT JOIN "User" u ON o.userid = u.userid
        JOIN vendor v ON o.vendorid = v.vendorid
        WHERE o.orderid = %s;
        """,
        (order_id,),
    )
    order_row = cur.fetchone()
    if not order_row:
        cur.close()
        conn.close()
        return jsonify({"error": "Order not found"}), 404

    order = {
        "orderid": order_row[0],
        "customer_name": order_row[1],
        "customer_email": order_row[2],
        "customer_phone": order_row[3],
        "vendor_name": order_row[4],
        "status": order_row[5],
        "totalamount": float(order_row[6]),
        "placedat": order_row[7].isoformat() if order_row[7] else None,
    }

    # items
    cur.execute(
        """
        SELECT m.name,
               oi.quantity,
               oi.unitprice
        FROM orderitem oi
        JOIN menuitem m ON oi.itemid = m.itemid
        WHERE oi.orderid = %s;
        """,
        (order_id,),
    )
    item_rows = cur.fetchall()
    cur.close()
    conn.close()

    items = []
    for name, qty, unitprice in item_rows:
        items.append(
            {
                "name": name,
                "quantity": qty,
                "unitprice": float(unitprice),
                "line_total": float(unitprice) * qty,
            }
        )

    order["items"] = items
    return jsonify(order)


# ---------- Customer order status lookup ----------


@app.get("/api/order-status/<int:order_id>")
def get_order_status(order_id: int):
    """Simple status lookup for customers."""
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT o.orderid,
               o.status,
               v.name AS vendor_name,
               o.totalamount,
               o.placedat
        FROM "Order" o
        JOIN vendor v ON o.vendorid = v.vendorid
        WHERE o.orderid = %s;
        """,
        (order_id,),
    )
    row = cur.fetchone()
    cur.close()
    conn.close()

    if not row:
        return jsonify({"error": "Order not found"}), 404

    return jsonify(
        {
            "orderid": row[0],
            "status": row[1],
            "vendor_name": row[2],
            "totalamount": float(row[3]),
            "placedat": row[4].isoformat() if row[4] else None,
        }
    )


@app.get("/api/health")
def health():
  return jsonify({"status": "ok"})


if __name__ == "__main__":
    app.run(debug=True)
