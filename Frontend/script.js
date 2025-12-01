const API_BASE = "http://127.0.0.1:5000/api";

async function init() {
  await Promise.all([loadMenu(), loadVendors()]);
}

window.addEventListener("DOMContentLoaded", init);


async function loadMenu() {
  const tbody = document.querySelector("#menu-table tbody");
  tbody.innerHTML = "<tr><td colspan='6'>Loading...</td></tr>";

  try {
    const res = await fetch(`${API_BASE}/menu`);
    const items = await res.json();

    if (!Array.isArray(items) || items.length === 0) {
      tbody.innerHTML = "<tr><td colspan='6'>No menu items found.</td></tr>";
      return;
    }

    tbody.innerHTML = "";
    for (const item of items) {
      const tr = document.createElement("tr");

      tr.innerHTML = `
        <td>${item.itemid}</td>
        <td>${item.vendor_name}</td>
        <td>${item.name}</td>
        <td>${item.category || ""}</td>
        <td>${item.price.toFixed(2)}</td>
        <td>${item.isavailable ? "Yes" : "No"}</td>
      `;

      tbody.appendChild(tr);
    }
  } catch (err) {
    console.error(err);
    tbody.innerHTML = "<tr><td colspan='6'>Error loading menu.</td></tr>";
  }
}


async function loadVendors() {
  const select = document.getElementById("add-vendor");
  try {
    const res = await fetch(`${API_BASE}/vendors`);
    const vendors = await res.json();

    for (const v of vendors) {
      const opt = document.createElement("option");
      opt.value = v.vendorid;
      opt.textContent = `${v.name} (${v.category})`;
      select.appendChild(opt);
    }
  } catch (err) {
    console.error("Error loading vendors", err);
  }
}


async function addItem() {
  const vendorid = document.getElementById("add-vendor").value;
  const name = document.getElementById("add-name").value.trim();
  const description = document.getElementById("add-description").value.trim();
  const category = document.getElementById("add-category").value.trim();
  const priceStr = document.getElementById("add-price").value;
  const statusEl = document.getElementById("add-status");

  statusEl.textContent = "";

  const price = parseFloat(priceStr);

  if (!vendorid || !name || isNaN(price)) {
    statusEl.textContent = "Vendor, name and price are required.";
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/menu/add`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        vendorid: Number(vendorid),
        name,
        description,
        category,
        price
      })
    });

    const data = await res.json();
    if (!res.ok) {
      statusEl.textContent = data.error || "Failed to add item.";
      return;
    }

    statusEl.textContent = `Item added with ID ${data.itemid}.`;
    loadMenu();

    document.getElementById("add-name").value = "";
    document.getElementById("add-description").value = "";
    document.getElementById("add-category").value = "";
    document.getElementById("add-price").value = "";
  } catch (err) {
    console.error(err);
    statusEl.textContent = "Error adding item.";
  }
}


async function updateOrder() {
  const orderIdStr = document.getElementById("order-id").value;
  const statusEl = document.getElementById("order-status");
  statusEl.textContent = "";

  const orderid = parseInt(orderIdStr, 10);
  if (isNaN(orderid)) {
    statusEl.textContent = "Please enter a valid Order ID.";
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/order/update-status`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ orderid })
    });

    const data = await res.json();
    statusEl.textContent = data.message || "Update complete.";
  } catch (err) {
    console.error(err);
    statusEl.textContent = "Error updating order.";
  }
}


async function disableItem() {
  const itemIdStr = document.getElementById("disable-id").value;
  const statusEl = document.getElementById("disable-status");
  statusEl.textContent = "";

  const itemid = parseInt(itemIdStr, 10);
  if (isNaN(itemid)) {
    statusEl.textContent = "Please enter a valid Item ID.";
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/menu/disable`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ itemid })
    });

    const data = await res.json();
    statusEl.textContent = data.message || "Item disabled.";
    loadMenu();
  } catch (err) {
    console.error(err);
    statusEl.textContent = "Error disabling item.";
  }
}
