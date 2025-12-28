terraform {
  required_version = ">= 1.0"

  required_providers {
{{ range $provider, $config := .providers }}
    {{ $provider }} = {
      source  = "{{ $config.source }}"
      version = "{{ $config.version }}"
    }
{{ end }}
  }

  backend "remote" {
    organization = "{{ .backend.organization }}"

    workspaces {
      name = "{{ .backend.workspace }}"
    }
  }
}
