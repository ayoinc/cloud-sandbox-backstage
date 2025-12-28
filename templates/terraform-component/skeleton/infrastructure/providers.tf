{{ range $provider, $config := .providers }}
provider "{{ $provider }}" {
{{ range $key, $value := $config.config }}
  {{ $key }} = {{ $value }}
{{ end }}
}
{{ end }}