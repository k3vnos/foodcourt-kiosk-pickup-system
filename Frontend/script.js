const API_BASE = "http://127.0.0.1:5000/api";

window.addEventListener("DOMContentLoaded", () => {
  initAdmin();
});

async function initAdmin() {
  await Promise.all([loadMenu(), loadVendors(), loadPendingOrders(), loadCompletedOrders()]);

  document.getElementById("add-item-btn").addEventListener("click", addMenuItem);
  document.getElementById("refresh-pending-btn").addEventListener("click", loadPendingOrders);
  document.getElementById("refresh-completed-btn").addEventListener("click", loadCompletedOrders);

  const closeButtons = [
    document.getElementById("close-modal-btn"),
    document.getElementById("modal-close-footer-btn"),
  ];
  closeButtons.forEach((btn) => {
    if (btn) {
      btn.addEventListener("click", hideOrderModal);
    }
  });

  const modalBackdrop = document.getElementById("order-modal");
  if (modalBackdrop) {
    modalBackdrop.addEventListener("click", (e) => {
      if (e.target === modalBackdrop) {
        hideOrderModal();
      }
    });
  }

  // Optional: auto-refresh orders every 10 seconds
  setInterval(() => {
    loadPendingOrders(false);
    loadCompletedOrders(false);
  }, 10000);
}

/* -------------------- Menu & Vendors -------------------- */

async function loadMenu() {
  const tbody = document.querySelector("#menu-table tbody");
  tbody.innerHTML = "<tr><td colspan='7'>Loading menu...</td></tr>";

  try {
    const res = await fetch(`${API_BASE}/menu`);
    const items = await res.json();

    tbody.innerHTML = "";
    if (!items.length) {
      tbody.innerHTML = "<tr><td colspan='7'>No menu items found.</td></tr>";
      return;
    }

    for (const item of items) {
      const tr = document.createElement("tr");
      tr.classList.add("fade-in");
      tr.innerHTML = `
        <td>${item.itemid}</td>
        <td>${item.vendor_name}</td>
        <td>${item.name}</td>
        <td>${item.category || ""}</td>
        <td>$${item.price.toFixed(2)}</td>
        <td>${item.isavailable ? "Yes" : "No"}</td>
        <td>
          ${
            item.isavailable
              ? `<button class="danger" onclick="disableItem(${item.itemid})">Disable</button>`
              : `<button onclick="enableItem(${item.itemid})">Enable</button>`
          }
        </td>
      `;
      tbody.appendChild(tr);
    }
  } catch (err) {
    console.error("Error loading menu", err);
    tbody.innerHTML = "<tr><td colspan='7'>Error loading menu.</td></tr>";
  }
}

async function loadVendors() {
  const select = document.getElementById("vendor-select");
  select.innerHTML = "<option value=''>Loading vendors...</option>";

  try {
    const res = await fetch(`${API_BASE}/vendors`);
    const vendors = await res.json();

    select.innerHTML = "<option value=''>Select a vendor</option>";
    for (const v of vendors) {
      const opt = document.createElement("option");
      opt.value = v.vendorid;
      const prep = v.avgprepminutes ? ` · ~${v.avgprepminutes} min` : "";
      opt.textContent = `${v.name} (${v.category})${prep}`;
      select.appendChild(opt);
    }
  } catch (err) {
    console.error("Error loading vendors", err);
    select.innerHTML = "<option value=''>Error loading vendors</option>";
  }
}

async function addMenuItem() {
  const vendorId = Number(document.getElementById("vendor-select").value);
  const name = document.getElementById("item-name").value.trim();
  const description = document.getElementById("item-description").value.trim();
  const priceValue = document.getElementById("item-price").value;
  const category = document.getElementById("item-category").value.trim();
  const statusEl = document.getElementById("add-status");

  if (!vendorId || !name || !priceValue) {
    statusEl.textContent = "Vendor, item name, and price are required.";
    return;
  }

  const price = Number(priceValue);

  try {
    statusEl.textContent = "Adding item...";
    const res = await fetch(`${API_BASE}/menu/add`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        vendorid: vendorId,
        name,
        description,
        price,
        category: category || null,
      }),
    });

    const data = await res.json();
    if (!res.ok) {
      statusEl.textContent = data.error || "Failed to add item.";
      return;
    }

    statusEl.textContent = data.message || "Item added.";
    // clear form
    document.getElementById("item-name").value = "";
    document.getElementById("item-description").value = "";
    document.getElementById("item-price").value = "";
    document.getElementById("item-category").value = "";
    loadMenu();
  } catch (err) {
    console.error("Error adding menu item", err);
    statusEl.textContent = "Error adding item.";
  }
}

async function disableItem(itemid) {
  const statusEl = document.getElementById("add-status"); // reuse status area
  try {
    
    const res = await fetch(`${API_BASE}/menu/disable`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ itemid }),
    });
    const data = await res.json();
    if (!res.ok) {
      statusEl.textContent = data.error || "Failed to disable item.";
      return;
    }
    
    loadMenu();
  } catch (err) {
    console.error("Error disabling menu item", err);
    statusEl.textContent = "Error disabling item.";
  }
}

async function enableItem(itemid) {
  try {
    const res = await fetch(`${API_BASE}/menu/enable`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ itemid })
    });

    const data = await res.json();

    // reload menu table
    loadMenu();
  } catch (err) {
    alert("Error enabling item.");
    console.error(err);
  }
}

/* -------------------- Orders dashboard -------------------- */

async function loadPendingOrders(showSpinner = true) {
  const tbody = document.querySelector("#pending-orders-table tbody");
  const statusEl = document.getElementById("orders-status");

  if (showSpinner) {
    tbody.innerHTML = "<tr><td colspan='7'>Loading pending orders...</td></tr>";
  }

  try {
    const res = await fetch(`${API_BASE}/orders/pending`);
    const orders = await res.json();

    tbody.innerHTML = "";
    if (!orders.length) {
      tbody.innerHTML = "<tr><td colspan='7'>No pending orders.</td></tr>";
      return;
    }

    for (const order of orders) {
      const tr = document.createElement("tr");
      tr.classList.add("fade-in");

      tr.innerHTML = `
        <td>${order.orderid}</td>
        <td>${order.customer_name || "Guest"}</td>
        <td>${order.vendor_name}</td>
        <td><span class="badge badge-${order.status.toLowerCase()}">${order.status}</span></td>
        <td>$${order.totalamount.toFixed(2)}</td>
        <td>${formatDateTime(order.placedat)}</td>
        <td class="nowrap">
          <button type="button" class="small" onclick="setOrderStatus(${order.orderid}, 'PREPARING')">Preparing</button>
          <button type="button" class="small" onclick="setOrderStatus(${order.orderid}, 'READY')">Ready</button>
          <button type="button" class="small danger" onclick="setOrderStatus(${order.orderid}, 'CANCELLED')">Cancel</button>
          <button type="button" class="small neutral" onclick="openOrderDetails(${order.orderid})">Details</button>
        </td>
      `;
      tbody.appendChild(tr);
    }
  } catch (err) {
    console.error("Error loading pending orders", err);
    statusEl.textContent = "Error loading pending orders.";
  }
}

async function loadCompletedOrders(showSpinner = true) {
  const tbody = document.querySelector("#completed-orders-table tbody");
  const statusEl = document.getElementById("orders-status");

  if (showSpinner) {
    tbody.innerHTML = "<tr><td colspan='7'>Loading completed orders...</td></tr>";
  }

  try {
    const res = await fetch(`${API_BASE}/orders/completed`);
    const orders = await res.json();

    tbody.innerHTML = "";
    if (!orders.length) {
      tbody.innerHTML = "<tr><td colspan='7'>No completed orders.</td></tr>";
      return;
    }

    for (const order of orders) {
      const tr = document.createElement("tr");
      tr.classList.add("fade-in");

      tr.innerHTML = `
        <td>${order.orderid}</td>
        <td>${order.customer_name || "Guest"}</td>
        <td>${order.vendor_name}</td>
        <td><span class="badge badge-${order.status.toLowerCase()}">${order.status}</span></td>
        <td>$${order.totalamount.toFixed(2)}</td>
        <td>${formatDateTime(order.placedat)}</td>
        <td class="nowrap">
          <button type="button" class="small" onclick="setOrderStatus(${order.orderid}, 'RECEIVED')">Back to Pending</button>
          <button type="button" class="small neutral" onclick="openOrderDetails(${order.orderid})">Details</button>
        </td>
      `;
      tbody.appendChild(tr);
    }
  } catch (err) {
    console.error("Error loading completed orders", err);
    statusEl.textContent = "Error loading completed orders.";
  }
}

async function setOrderStatus(orderid, status) {
  const statusEl = document.getElementById("orders-status");
  statusEl.textContent = `Updating order ${orderid} to ${status}...`;

  try {
    const res = await fetch(`${API_BASE}/order/update`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ orderid, status }),
    });
    const data = await res.json();

    if (!res.ok) {
      statusEl.textContent = data.error || "Failed to update order.";
      return;
    }

    statusEl.textContent = data.message || "Order updated.";
    loadPendingOrders(false);
    loadCompletedOrders(false);
  } catch (err) {
    console.error("Error updating order", err);
    statusEl.textContent = "Error updating order.";
  }
}

async function openOrderDetails(orderid) {
  const modal = document.getElementById("order-modal");
  const tbody = document.querySelector("#detail-items-table tbody");

  // clear existing
  tbody.innerHTML = "<tr><td colspan='4'>Loading...</td></tr>";
  document.getElementById("detail-order-id").textContent = orderid;
  document.getElementById("detail-customer").textContent = "";
  document.getElementById("detail-vendor").textContent = "";
  document.getElementById("detail-status").textContent = "";
  document.getElementById("detail-total").textContent = "";
  document.getElementById("detail-placed").textContent = "";

  modal.classList.remove("hidden");

  try {
    const res = await fetch(`${API_BASE}/order/${orderid}`);
    const data = await res.json();

    if (!res.ok) {
      tbody.innerHTML = "<tr><td colspan='4'>Order not found.</td></tr>";
      return;
    }

    document.getElementById("detail-order-id").textContent = data.orderid;
    document.getElementById("detail-customer").textContent =
      `${data.customer_name || "Guest"} (${data.customer_email || "no email"})`;
    document.getElementById("detail-vendor").textContent = data.vendor_name;
    document.getElementById("detail-status").textContent = data.status;
    document.getElementById("detail-total").textContent = data.totalamount.toFixed(2);
    document.getElementById("detail-placed").textContent = formatDateTime(data.placedat);

    tbody.innerHTML = "";
    if (!data.items || !data.items.length) {
      tbody.innerHTML = "<tr><td colspan='4'>No items.</td></tr>";
    } else {
      for (const item of data.items) {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>${item.name}</td>
          <td>${item.quantity}</td>
          <td>$${item.unitprice.toFixed(2)}</td>
          <td>$${item.line_total.toFixed(2)}</td>
        `;
        tbody.appendChild(tr);
      }
    }
  } catch (err) {
    console.error("Error loading order details", err);
    tbody.innerHTML = "<tr><td colspan='4'>Error loading order details.</td></tr>";
  }
}

function hideOrderModal() {
  const modal = document.getElementById("order-modal");
  if (modal) modal.classList.add("hidden");
}

/* -------------------- Utils -------------------- */

function formatDateTime(isoString) {
  if (!isoString) return "";
  const d = new Date(isoString);
  if (Number.isNaN(d.getTime())) return isoString;
  return d.toLocaleString();
}
