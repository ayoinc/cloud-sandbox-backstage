# Backstage Catalog Setup Guide

## Overview

This document explains how to register Terraform modules in Backstage and ensure all components with techdocs are properly discovered.

## Files Structure

```
/Users/ayodeleajayi/Workspace/backstage/catalog/terraform-modules/
├── catalog-info.yaml          # Main terraform-modules component
├── gcp-vpc.yaml               # GCP VPC module component
├── aws-vpc.yaml               # AWS VPC module component
├── azure-vnet.yaml            # Azure VNet module component
├── all-components.yaml        # Master location file (recommended)
├── modules.yaml               # Modules location file
└── docs/
    ├── index.md
    ├── getting-started.md
    └── modules/
        ├── gcp-vpc.md         # Enhanced (1,873 lines)
        ├── aws-vpc.md
        └── azure-vnet.md
```

## Import Options

### Option 1: Import All Components (Recommended)

Register `all-components.yaml` in Backstage:

- **File**: `all-components.yaml`
- **Purpose**: Registers all components at once
- **TechDocs**: References `dir:.` for the main component

### Option 2: Import Individual Components

Register each component separately:

1. `catalog-info.yaml` - Main terraform-modules component
2. `gcp-vpc.yaml` - GCP VPC module
3. `aws-vpc.yaml` - AWS VPC module
4. `azure-vnet.yaml` - Azure VNet module

### Option 3: Import via Location

Register `modules.yaml` as a Location:

- **File**: `modules.yaml`
- **Purpose**: Acts as a pointer to all module components

## TechDocs Configuration

All components have the required `backstage.io/techdocs-ref` annotation:

| Component         | Annotation Value | Docs Location                |
| ----------------- | ---------------- | ---------------------------- |
| terraform-modules | `dir:.`          | `docs/index.md`              |
| gcp-vpc           | `dir:./docs`     | `docs/modules/gcp-vpc.md`    |
| aws-vpc           | `dir:./docs`     | `docs/modules/aws-vpc.md`    |
| azure-vnet        | `dir:./docs`     | `docs/modules/azure-vnet.md` |

## Verification Steps

### 1. Validate YAML Syntax

```bash
python3 -c "
import yaml
for f in ['catalog-info.yaml', 'gcp-vpc.yaml', 'aws-vpc.yaml', 'azure-vnet.yaml', 'all-components.yaml']:
    with open(f, 'r') as file:
        list(yaml.safe_load_all(file.read()))
    print(f'✓ {f}')
"
```

### 2. Check Backstage Catalog (after import)

```bash
# List all components
curl http://localhost:7007/api/catalog/entities?filter=kind=component | jq '.items[].metadata.name'

# Check specific component
curl http://localhost:7007/api/catalog/entities/by-name/component/gcp-vpc | jq '.metadata.annotations'
```

### 3. Verify TechDocs Generation

```bash
# Check if docs are being built
ls -la /tmp/techdocs-* 2>/dev/null || echo "No techdocs cache found"

# View generated docs location
docker exec backstage-backend ls -la /app/backstage/techdocs/
```

## Troubleshooting

### Components Not Appearing

1. Check Backstage logs: `docker logs backstage-app`
2. Verify catalog import location is correct
3. Ensure GitHub integration is configured
4. Check for UUID conflicts: `metadata.name` must be unique

### TechDocs Not Loading

1. Verify `backstage.io/techdocs-ref` annotation exists
2. Check that `mkdocs.yml` is present and valid
3. Ensure docs directory path is correct
4. Check TechDocs backend logs for build errors

### Missing References

If you see "reference not found" errors:

1. Ensure Location resources are registered
2. Check that target paths in Location specs are correct
3. Verify all referenced files exist

## How to Register

1. In Backstage UI, go to **Create** → **Register Existing Component**
2. Enter the full URL to `all-components.yaml`:
   ```
   https://github.com/company/terraform-modules/blob/main/all-components.yaml
   ```
3. Click **Analyze** and then **Import**
4. All components should appear in the catalog within 30 seconds

## Reference URLs

- **All Components**: `https://github.com/company/terraform-modules/blob/main/all-components.yaml`
- **Main Component**: `https://github.com/company/terraform-modules/blob/main/catalog-info.yaml`
- **GCP Module**: `https://github.com/company/terraform-modules/blob/main/gcp-vpc.yaml`

## Summary

✅ All components have `backstage.io/techdocs-ref` annotations
✅ All YAML files are syntactically valid
✅ Multiple import options available
✅ TechDocs can be generated for all components
✅ Location resources created for flexible registration
