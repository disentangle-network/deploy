# Golden File Tests

Golden file (snapshot) tests for the Disentangle Helm chart. These tests prevent regressions by comparing rendered chart output against known-good snapshots.

## Test Configurations

| File | Description |
|------|-------------|
| `default.yaml` | Default values (5 nodes, no traffic, no ingress) |
| `minimal.yaml` | Minimal 3-node dev setup with persistence disabled |
| `full-features.yaml` | All features enabled (7 nodes, traffic, ingress, LoadBalancer) |
| `no-serviceaccount.yaml` | ServiceAccount creation disabled |
| `custom-resources.yaml` | Custom CPU/memory resource limits with 10 nodes |

## Usage

### Verify Chart Changes

Run after modifying chart templates to detect unintended changes:

```bash
./verify.sh
```

Exit codes:
- `0` - All tests passed
- `1` - One or more tests failed (templates changed)

### Update Golden Files

Run when template changes are intentional and you want to update the snapshots:

```bash
./update.sh
```

This regenerates all golden files with the latest chart output.

## CI Integration

Add to CI pipeline to prevent regressions:

```yaml
# .github/workflows/helm-test.yml
- name: Run Golden File Tests
  run: |
    cd deploy/tests/golden
    ./verify.sh
```

## How It Works

1. **Golden files** - Committed YAML files containing known-good `helm template` output
2. **verify.sh** - Renders chart with same config, diffs against golden files
3. **update.sh** - Regenerates golden files when changes are intentional

## Adding New Test Cases

1. Add new configuration to both `update.sh` and `verify.sh`
2. Run `./update.sh` to generate the golden file
3. Commit the new golden file
4. Run `./verify.sh` to ensure it passes

## Example

```bash
# Modify a template
vim ../../helm/disentangle/templates/statefulset.yaml

# Test for regressions
./verify.sh
# FAIL: default.yaml differs from golden file

# Review diff
./verify.sh | less

# If change is intentional
./update.sh

# Verify again
./verify.sh
# PASS: all tests

# Commit updated golden files
git add *.yaml
git commit -m "Update golden files for new StatefulSet annotations"
```
