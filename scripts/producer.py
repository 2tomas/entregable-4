"""Genera eventos Kinesis ordenados y fuera de orden para validar event time."""

import argparse
import json
import random
import uuid
from datetime import datetime, timedelta, timezone

import boto3

MAX_RECORDS_PER_REQUEST = 500


def parse_args():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stream-name", default="terraform-kinesis-dev")
    parser.add_argument("--region", default="us-east-1")
    parser.add_argument("--records", type=int, default=120)
    parser.add_argument("--users", type=int, default=10)
    parser.add_argument(
        "--late-every",
        type=int,
        default=10,
        help="Cada N eventos atrasa created_at; 0 desactiva el atraso.",
    )
    parser.add_argument(
        "--late-seconds",
        type=int,
        default=20,
        help="Segundos de atraso aplicados a los eventos fuera de orden.",
    )
    parser.add_argument(
        "--endpoint-url",
        default=None,
        help="Endpoint alternativo (solo para probar el producer, no Managed Flink).",
    )
    return parser.parse_args()


def build_event(index, users, late_every, late_seconds):
    now = datetime.now(timezone.utc)
    is_out_of_order = late_every > 0 and (index + 1) % late_every == 0
    created_at = now - timedelta(seconds=late_seconds if is_out_of_order else 0)
    user_id = f"user-{index % users:04d}"
    return user_id, {
        "event_id": str(uuid.uuid4()),
        "event_type": random.choice(["page_view", "product_view", "checkout"]),
        "user_id": user_id,
        "sequence": index + 1,
        "created_at": created_at.isoformat().replace("+00:00", "Z"),
    }


def main():
    args = parse_args()
    if args.records < 1 or args.users < 1:
        raise SystemExit("--records y --users deben ser mayores que cero")
    if args.late_every < 0 or args.late_seconds < 0:
        raise SystemExit("--late-every y --late-seconds no pueden ser negativos")

    client_options = {"region_name": args.region}
    if args.endpoint_url:
        client_options["endpoint_url"] = args.endpoint_url
    client = boto3.client("kinesis", **client_options)

    records = []
    for index in range(args.records):
        partition_key, event = build_event(
            index, args.users, args.late_every, args.late_seconds
        )
        records.append(
            {
                "PartitionKey": partition_key,
                "Data": (json.dumps(event) + "\n").encode("utf-8"),
            }
        )

    failed_results = []
    for offset in range(0, len(records), MAX_RECORDS_PER_REQUEST):
        batch = records[offset : offset + MAX_RECORDS_PER_REQUEST]
        response = client.put_records(StreamName=args.stream_name, Records=batch)
        failed_results.extend(
            result for result in response["Records"] if "ErrorCode" in result
        )

    failed = len(failed_results)
    print(f"Enviados: {len(records) - failed}/{len(records)}; fallidos: {failed}")
    if failed_results:
        for result in failed_results:
            print(f"{result['ErrorCode']}: {result.get('ErrorMessage', '')}")
        raise SystemExit(1)


if __name__ == "__main__":
    main()
