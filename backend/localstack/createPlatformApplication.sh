#!/bin/bash
set -x

# iOS Push
awslocal sns create-platform-application \
    --name ios-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=DAMMY

# iOS VoIP Push
awslocal sns create-platform-application \
    --name ios-voip-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=DAMMY

set +x


