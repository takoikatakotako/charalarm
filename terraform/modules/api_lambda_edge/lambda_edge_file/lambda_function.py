import hashlib
import base64
import json
from typing import Dict, Any

def hash_payload(payload: str) -> str:
    sha256_hash = hashlib.sha256(payload.encode("utf-8")).hexdigest()
    return sha256_hash

def lambda_handler(event: Dict[str, Any], _context: Any) -> Dict[str, Any]:
    request = event["Records"][0]["cf"]["request"]
    print("originalRequest", json.dumps(request))
    
    if "body" not in request or "data" not in request["body"]:
        return request
    
    body = request["body"]["data"]
    decoded_body = base64.b64decode(body).decode("utf-8")
    
    request.setdefault("headers", {})["x-amz-content-sha256"] = [
        {"key": "x-amz-content-sha256", "value": hash_payload(decoded_body)}
    ]
    
    print("modifiedRequest", json.dumps(request))
    return request
