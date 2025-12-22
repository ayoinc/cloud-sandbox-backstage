# ${{ values.name }}

${{ values.description }}

## Build Image

```bash
packer init .
packer validate .
packer build image.pkr.hcl
```

## Configuration

- Provider: ${{ values.cloud_provider }}
- Base OS: ${{ values.base_os }}
- Region: ${{ values.region }}
