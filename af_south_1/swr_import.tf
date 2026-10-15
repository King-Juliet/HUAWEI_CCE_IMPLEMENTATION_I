# One-time: adopt the SWR organization left over from the first, failed pipeline run (it exists
# in Huawei Cloud but not in Terraform state, so creating it fails with "conflict in the
# request"). Once the first apply succeeds this file can be deleted.

import {
  to = module.juliet_swr.huaweicloud_swr_organization.this
  id = "juliet-cce"
}