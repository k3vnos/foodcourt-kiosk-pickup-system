const API_BASE = "http://127.0.0.1:5000/api";

async function checkOrderStatus() {
  const input = document.getElementById("status-order-id");
  const messageEl = document.getElementById("status-message");
  const resultEl = document.getElementById("status-result");

  messageEl.textContent = "";
  resultEl.innerHTML = `
    <p class="card-description">Checking order status...</p>
  `;

  const raw = input.value.trim();
  const orderId = parseInt(raw, 10);

  if (isNaN(orderId) || orderId <= 0) {
    messageEl.textContent = "Please enter a valid Order ID.";
    resultEl.innerHTML = `
      <p class="card-description">
        No order selected yet. Enter an Order ID and click <strong>Check Status</strong>.
      </p>
    `;
    return;
  }

  try {
    const res = await fetch(`${API_BASE}/order-status/${orderId}`);

    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      messageEl.textContent = data.error || "Order not found.";
      resultEl.innerHTML = `
        <p class="card-description">
          We could not find an order with ID <strong>${orderId}</strong>.
        </p>
      `;
      return;
    }

    const data = await res.json();
    renderOrderStatus(data);
  } catch (err) {
    console.error("Error fetching order status:", err);
    messageEl.textContent = "Error while fetching order status.";
    resultEl.innerHTML = `
      <p class="card-description">
        Something went wrong while checking your order. Please try again.
      </p>
    `;
  }
}

function renderOrderStatus(order) {
  const resultEl = document.getElementById("status-result");

  const {
    orderid,
    status,
    is_completed,
    vendor_name,
    customer_name,
    placed_at,
    estimated_ready_at,
    total
  } = order;

  const statusLabel = formatStatus(status);
  const completedText = is_completed
    ? "This order is <strong>completed</strong>."
    : "This order is <strong>still in progress</strong>.";

  const placed = placed_at ? new Date(placed_at).toLocaleString() : "N/A";
  const est = estimated_ready_at
    ? new Date(estimated_ready_at).toLocaleString()
    : "Not set";

  resultEl.innerHTML = `
    <h3>Order #${orderid}</h3>
    <p class="card-description">
      <strong>Status:</strong> ${statusLabel}<br>
      ${completedText}
    </p>
    <p class="card-description">
      <strong>Vendor:</strong> ${vendor_name || "N/A"}<br>
      <strong>Customer:</strong> ${customer_name || "Guest"}<br>
      <strong>Total:</strong> ${typeof total === "number" ? "$" + total.toFixed(2) : "N/A"}
    </p>
    <p class="card-description">
      <strong>Placed At:</strong> ${placed}<br>
      <strong>Estimated Ready:</strong> ${est}
    </p>
  `;
}

function formatStatus(status) {
  if (!status) return "Unknown";

  switch (status.toUpperCase()) {
    case "RECEIVED":
      return "Received (waiting to be prepared)";
    case "PREPARING":
      return "Preparing";
    case "READY":
      return "Ready for pickup";
    case "PICKED_UP":
      return "Picked up";
    case "CANCELLED":
      return "Cancelled";
    default:
      return status;
  }
}
