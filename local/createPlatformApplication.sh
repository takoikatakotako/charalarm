#!/bin/bash
set -x

# iOS Push
awslocal sns create-platform-application \
    --name ios-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=DAMMY \
    --region ap-northeast-1

# iOS VoIP Push
awslocal sns create-platform-application \
    --name ios-voip-push-platform-application \
    --platform APNS \
    --attributes PlatformCredential=DAMMY \
    --region ap-northeast-1

set +x


