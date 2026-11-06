#!/usr/bin/env python3
# Participant Replay Tool Starter
# Complete this tool to safely migrate messages from DLQ to orders.queue
import json
import sys

def replay(src_file="orders_dlq.json", dst_file="orders_queue.json"):
    print(f"Replaying messages from {src_file} to {dst_file}...")
    # TODO: Read from src_file, append to dst_file, and clear replayed entries

if __name__ == '__main__':
    replay()
