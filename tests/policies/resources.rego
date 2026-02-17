package main

import rego.v1

# Require resource limits on all containers
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.resources.limits
    msg := sprintf("Container '%s' in %s '%s' must set resource limits", [container.name, input.kind, input.metadata.name])
}

# Require resource requests on all containers
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.resources.requests
    msg := sprintf("Container '%s' in %s '%s' must set resource requests", [container.name, input.kind, input.metadata.name])
}

# Require CPU limits
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' in %s '%s' must set CPU limits", [container.name, input.kind, input.metadata.name])
}

# Require memory limits
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.resources.limits.memory
    msg := sprintf("Container '%s' in %s '%s' must set memory limits", [container.name, input.kind, input.metadata.name])
}
