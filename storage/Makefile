# Local
.PHONY: sync-development-to-local-dryrun
sync-development-to-local-dryrun:
	aws s3 sync s3://resource.charalarm-development.swiswiswift.com resources --dryrun --profile charalarm-development

.PHONY: sync-development-to-local
sync-development-to-local-dryrun:
	aws s3 sync s3://resource.charalarm-development.swiswiswift.com resources --profile charalarm-development



# Development
.PHONY: development-to-local
development-to-local:
	aws s3 sync s3://resource.charalarm-development.swiswiswift.com resources --profile charalarm-development


# Staging
.PHONY: local-to-staging-dryrun
local-to-staging-dryrun:
	aws s3 sync resources s3://resource.charalarm-staging.swiswiswift.com --dryrun --profile charalarm-staging

.PHONY: local-to-staging
local-to-staging:
	aws s3 sync resources s3://resource.charalarm-staging.swiswiswift.com --profile charalarm-staging

# Production
.PHONY: local-to-production
local-to-production:
	aws s3 sync resources s3://resource.charalarm-staging.swiswiswift.com --dryrun --profile charalarm-staging
