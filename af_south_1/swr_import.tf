# One-time: adopt the SWR organization and the two repositories left over from the first,
# failed pipeline run (they exist in Huawei Cloud but not in Terraform state, so creating them
# fails with "conflict in the request"). Once the first apply succeeds this file can be deleted.

import {
  to = module.juliet_swr.huaweicloud_swr_organization.this
  id = "juliet-cce"
}

import {
  to = module.juliet_swr.huaweicloud_swr_repository.this["frontend"]
  id = "juliet-cce,imto-test-frontend"
}

import {
  to = module.juliet_swr.huaweicloud_swr_repository.this["backend"]
  id = "juliet-cce,imto-test-backend"
}