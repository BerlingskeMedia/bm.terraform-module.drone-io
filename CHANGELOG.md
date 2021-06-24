---
# 0.7.0
## Main Changes
    - Add permissions to fetch images from any ECR.

# 0.6.0
## Main Changes
    - Output builder username to have it when we need to apply policy outside of the module to it (ex. with `aws_iam_user_policy_attachment`).

# 0.5.0
## Main Changes
    - Add required permissions to run standalone tasks
    - Due to security concern - restricted permissions for various 
    actions to specific resources instead of global wildcard 

# 0.4.0
## Main Changes
    - Terraform v0.14.x support
    - Aws provider 3.0 by default

# 0.3.0
## Main Changes
    - Terraform v0.13.x support

# 0.2.0
## Main changes
    - add outputs `access_key` and `secret_key`, which returns simple strings, 
        instead of fetching data of resources, created inside this module (it's stupid). 
        However leaving old outputs in terms of backward compability.
# 0.1.1
## Main changes
    - Added missing actions :
        - ecs:RegisterTaskDefinition
        - ecs:UpdateService
    - Started tagging
    - Added versions.tf

# 0.1.0

## Main changes
* Start
