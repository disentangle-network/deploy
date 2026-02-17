package main

import rego.v1

# Require standard Kubernetes labels
deny contains msg if {
    required_labels := {"app.kubernetes.io/name", "app.kubernetes.io/instance"}
    provided := {l | some l, _ in input.metadata.labels}
    missing := required_labels - provided
    count(missing) > 0
    msg := sprintf("%s '%s' is missing required labels: %v", [input.kind, input.metadata.name, missing])
}

# Require managed-by label
warn contains msg if {
    not input.metadata.labels["app.kubernetes.io/managed-by"]
    msg := sprintf("%s '%s' should have app.kubernetes.io/managed-by label", [input.kind, input.metadata.name])
}
