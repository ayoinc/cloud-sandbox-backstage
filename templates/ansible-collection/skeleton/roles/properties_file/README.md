# ${{ values.namespace }}.${{ values.collectionName }}.properties_file

Keeps entries of one properties file in the declared state. Comments and
entries the role does not know about are left alone.

```yaml
- name: Configure the application
  hosts: app
  become: true
  roles:
    - role: ${{ values.namespace }}.${{ values.collectionName }}.properties_file
      vars:
        properties_file_path: /etc/app/app.properties
        properties_file_entries:
          server.port: 8443
          server.tls: true
        properties_file_absent:
          - legacy.mode
```

Arguments are described in `meta/argument_specs.yml`.
