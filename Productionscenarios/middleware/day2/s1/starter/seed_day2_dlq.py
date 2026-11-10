#!/usr/bin/env python3
import json
import os

DLQ_FILE = "orders_dlq.json"
QUEUE_FILE = "orders_queue.json"
DB_FILE = "processed_orders.json"

messages = []

# 50 legitimate customer orders
for i in range(1, 51):
    messages.append({
        "order_id": f"ORD-2026-{1000+i}",
        "customer_id": f"CUST-{500+i}",
        "total_amount": round(25.50 + (i * 2.15), 2),
        "items_count": (i % 4) + 1,
        "is_poison_pill": False
    })

# 10 malformed poison pills
for i in range(1, 11):
    messages.append({
        "order_id": None if i % 2 == 0 else f"ORD-CORRUPT-{i}",
        "customer_id": f"CUST-ERR-{i}",
        "total_amount": -10.0 if i % 2 == 0 else 0.0,
        "items_count": 0,
        "is_poison_pill": True
    })

with open(DLQ_FILE, 'w') as f:
    json.dump(messages, f, indent=2)

# Empty primary queue and DB
with open(QUEUE_FILE, 'w') as f:
    json.dump([], f)
with open(DB_FILE, 'w') as f:
    json.dump([], f)

print(f"[SEED] Injected {len(messages)} messages (50 valid, 10 poison pills) into {DLQ_FILE}.")
