const API_BASE = "http://127.0.0.1:5000/api";

let allMenuItems = [];
let vendors = [];
let cart = {}; // itemid -> { item, qty }

window.addEventListener("DOMContentLoaded", initCustomerPage);

async function initCustomerPage() {
  await Promise.all([loadVendorsCustomer(), loadMenuCustomer()]);
  renderVendorOptions();
  renderMenuForSelectedVendor();
  renderCart();
}

/* ---------- Load data ---------- */

async function loadVendorsCustomer() {
  try {
    const res = await fetch(`${API_BASE}/vendors`);
    vendors = await res.json();
  } catch (e) {
    console.error("Error loading vendors", e);
  }
}

async function loadMenuCustomer() {
  try {
    const res = await fetch(`${API_BASE}/menu`);
    allMenuItems = await res.json();
  } catch (e) {
    console.error("Error loading menu", e);
  }
}

/* ---------- Rendering ---------- */

function renderVendorOptions() {
  const select = document.getElementById("cust-vendor-select");
  select.innerHTML = "";

  if (!vendors.length) {
    const opt = document.createElement("option");
    opt.textContent = "No vendors available";
    opt.value = "";
    select.appendChild(opt);
    return;
  }

  for (const v of vendors) {
    const opt = document.createElement("option");
    opt.value = v.vendorid;
    const prep = v.avgprepminutes ? ` · ~${v.avgprepminutes} min` : "";
    opt.textContent = `${v.name} (${v.category})${prep}`;
    select.appendChild(opt);
  }

  select.addEventListener("change", () => {
    cart = {}; // reset cart when switching vendor
    renderMenuForSelectedVendor();
    renderCart();
  });
}

function getSelectedVendorId() {
  const select = document.getElementById("cust-vendor-select");
  const val = select.value;
  return val ? Number(val) : null;
}

function renderMenuForSelectedVendor() {
  const container = document.getElementById("cust-menu-list");
  container.innerHTML = "";

  const vendorId = getSelectedVendorId();
  if (!vendorId) {
    container.innerHTML = "<p class='card-description'>Select a vendor to see menu items.</p>";
    return;
  }

  const items = allMenuItems.filter(
    (m) => m.vendorid === vendorId && m.isavailable
  );

  if (!items.length) {
    container.innerHTML = "<p class='card-description'>No available items for this vendor.</p>";
    return;
  }

  for (const item of items) {
    const card = document.createElement("div");
    card.className = "card fade-in";

    card.innerHTML = `
      <h3>${item.name}</h3>
      <p class="card-description">
        ${item.description || "No description."}
      </p>
      <p class="card-description">
        <strong>$${item.price.toFixed(2)}</strong> · ${item.category || "Item"}
      </p>
      <div style="display:flex; gap:8px; align-items:center; margin-top:8px;">
        <button type="button" onclick="addToCart(${item.itemid})">Add to tray</button>
      </div>
    `;

    container.appendChild(card);
  }
}

function renderCart() {
  const container = document.getElementById("cart-items");
  const totalEl = document.getElementById("cart-total");

  container.innerHTML = "";
  let total = 0;

  const entries = Object.values(cart);

  if (!entries.length) {
    container.innerHTML = "<p class='card-description'>Your tray is empty.</p>";
    totalEl.textContent = "$0.00";
    return;
  }

  for (const entry of entries) {
    const { item, qty } = entry;
    const lineTotal = item.price * qty;
    total += lineTotal;

    const row = document.createElement("div");
    row.className = "card fade-in";
    row.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center;">
        <div>
          <strong>${item.name}</strong>
          <p class="card-description" style="margin-top:2px;">
            $${item.price.toFixed(2)} × ${qty} = $${lineTotal.toFixed(2)}
          </p>
        </div>
        <div style="display:flex; gap:6px; align-items:center;">
          <button type="button" class="small" onclick="changeQty(${item.itemid}, -1)">−</button>
          <span>${qty}</span>
          <button type="button" class="small" onclick="changeQty(${item.itemid}, 1)">+</button>
        </div>
      </div>
    `;
    container.appendChild(row);
  }

  totalEl.textContent = `$${total.toFixed(2)}`;
}

/* ---------- Cart helpers ---------- */

function addToCart(itemid) {
  const item = allMenuItems.find((m) => m.itemid === itemid);
  if (!item) return;

  if (!cart[itemid]) {
    cart[itemid] = { item, qty: 1 };
  } else {
    cart[itemid].qty += 1;
  }
  renderCart();
}

function changeQty(itemid, delta) {
  if (!cart[itemid]) return;
  cart[itemid].qty += delta;
  if (cart[itemid].qty <= 0) {
    delete cart[itemid];
  }
  renderCart();
}

/* ---------- Place order ---------- */

async function placeCustomerOrder() {
  const statusEl = document.getElementById("cust-status");
  statusEl.textContent = "";

  const vendorId = getSelectedVendorId();
  if (!vendorId) {
    statusEl.textContent = "Please select a vendor.";
    return;
  }

  const entries = Object.values(cart);
  if (!entries.length) {
    statusEl.textContent = "Your tray is empty.";
    return;
  }

  const name = document.getElementById("cust-name").value.trim();
  const email = document.getElementById("cust-email").value.trim();
  const phone = document.getElementById("cust-phone").value.trim();

  const payload = {
    customer: {
      name: name || null,
      email: email || null,
      phone: phone || null,
    },
    vendorid: vendorId,
    items: entries.map((e) => ({
      itemid: e.item.itemid,
      quantity: e.qty,
    })),
  };

  try {
    statusEl.textContent = "Placing order...";
    const res = await fetch(`${API_BASE}/orders`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      statusEl.textContent = data.error || "Failed to place order.";
      return;
    }

    statusEl.textContent = `Order #${data.orderid} placed! Total $${data.total.toFixed(
      2
    )}. Status: RECEIVED. Keep this order ID to track your status.`;
    cart = {};
    renderCart();
  } catch (e) {
    console.error("Error placing order", e);
    statusEl.textContent = "Error placing order.";
  }
}
