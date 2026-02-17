package main

import rego.v1

# Deny containers running as root
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.securityContext.runAsNonRoot
    msg := sprintf("Container '%s' in %s '%s' must set securityContext.runAsNonRoot=true", [container.name, input.kind, input.metadata.name])
}

# Deny privileged containers
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    container.securityContext.privileged
    msg := sprintf("Container '%s' in %s '%s' must not be privileged", [container.name, input.kind, input.metadata.name])
}

# Deny privilege escalation
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    container.securityContext.allowPrivilegeEscalation
    msg := sprintf("Container '%s' in %s '%s' must set allowPrivilegeEscalation=false", [container.name, input.kind, input.metadata.name])
}

# Deny missing capability drops
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.securityContext.capabilities.drop
    msg := sprintf("Container '%s' in %s '%s' must drop all capabilities", [container.name, input.kind, input.metadata.name])
}

# Require seccomp profile at pod level
deny contains msg if {
    input.kind == "StatefulSet"
    not input.spec.template.spec.securityContext.seccompProfile
    msg := sprintf("%s '%s' must set seccompProfile", [input.kind, input.metadata.name])
}

# Deny host networking
deny contains msg if {
    input.kind == "StatefulSet"
    input.spec.template.spec.hostNetwork
    msg := sprintf("%s '%s' must not use host networking", [input.kind, input.metadata.name])
}

# Deny host PID
deny contains msg if {
    input.kind == "StatefulSet"
    input.spec.template.spec.hostPID
    msg := sprintf("%s '%s' must not use host PID namespace", [input.kind, input.metadata.name])
}
