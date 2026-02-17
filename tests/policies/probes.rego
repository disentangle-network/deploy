package main

import rego.v1

# Require liveness probe
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.livenessProbe
    msg := sprintf("Container '%s' in %s '%s' must define a livenessProbe", [container.name, input.kind, input.metadata.name])
}

# Require readiness probe
deny contains msg if {
    input.kind == "StatefulSet"
    some container in input.spec.template.spec.containers
    not container.readinessProbe
    msg := sprintf("Container '%s' in %s '%s' must define a readinessProbe", [container.name, input.kind, input.metadata.name])
}
