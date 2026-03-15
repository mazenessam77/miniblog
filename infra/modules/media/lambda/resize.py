"""
Lambda: resize uploaded images into thumb (300×300) and medium (1200×900).

Trigger: S3 ObjectCreated on uploads/ prefix
Input:   uploads/<uuid>.<ext>
Output:  resized/thumb/<uuid>.<ext>
         resized/medium/<uuid>.<ext>
"""

import io
import os

import boto3
from PIL import Image

s3 = boto3.client("s3")

SIZES = {
    "thumb": (300, 300),
    "medium": (1200, 900),
}


def handler(event, context):
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]

        if not key.startswith("uploads/"):
            continue

        filename = key[len("uploads/"):]  # uuid.ext

        print(f"Resizing {key} in bucket {bucket}")

        obj = s3.get_object(Bucket=bucket, Key=key)
        img = Image.open(io.BytesIO(obj["Body"].read()))

        # Normalise colour mode (handles CMYK, P, LA, etc.)
        if img.mode not in ("RGB", "RGBA"):
            img = img.convert("RGB")

        use_png = filename.lower().endswith(".png")
        fmt = "PNG" if use_png else "JPEG"

        for size_name, (max_w, max_h) in SIZES.items():
            copy = img.copy()
            copy.thumbnail((max_w, max_h), Image.LANCZOS)

            if fmt == "JPEG" and copy.mode == "RGBA":
                copy = copy.convert("RGB")

            buf = io.BytesIO()
            copy.save(buf, format=fmt, quality=85, optimize=True)
            buf.seek(0)

            out_key = f"resized/{size_name}/{filename}"
            s3.put_object(
                Bucket=bucket,
                Key=out_key,
                Body=buf.read(),
                ContentType="image/png" if use_png else "image/jpeg",
            )
            print(f"Saved {out_key}")

    return {"statusCode": 200}
