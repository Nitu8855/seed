/**
 * Copyright (c) 2023. Faurecia Clarion Electronics All rights reserved.
 */

// Features for the mcu-coverity docker template agent.

import groovy.transform.Field

@Field
def dockerTemplateAgentFeatures = [
    tmpfs_tmp: true  // The mcu coverity build needs to be able to write on /tmp
]

return this;
