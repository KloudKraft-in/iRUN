#!/usr/bin/env python3
import json
import logging
import sys

logging.basicConfig(level=logging.INFO, format='%(asctime)s [%(levelname)s] %(message)s')
logger = logging.getLogger("OrderConsumer")

# BUGGY CONSUMER: Lacks schema validation, crashes on null or negative amounts!
def on_message(payload_str):
    try:
        payload = json.loads(payload_str)
        # Unhandled assertion/KeyError if schema is broken
        order_id = payload['order_id']
        amount = payload['total_amount']
        
        if order_id is None or amount <= 0:
            raise ValueError(f"Corrupt payload detected: {payload}")
            
        logger.info(f"Successfully processed order #{order_id} for ${amount:.2f}")
        return True, "ACK"
    except Exception as e:
        logger.error(f"FATAL CONSUMER CRASH: {e} -> Rejecting message to DLQ")
        # In unpatched consumer, this triggers basic_reject(requeue=False), dumping to DLQ!
        return False, "REJECT_TO_DLQ"

if __name__ == '__main__':
    print("[ORDER CONSUMER] Initialized in naive legacy mode.")
