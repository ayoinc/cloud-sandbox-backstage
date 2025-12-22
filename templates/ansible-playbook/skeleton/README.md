# ${{ values.name | title }}

${{ values.description }}

## Overview

This Ansible playbook was generated using the AWX Backstage platform. It follows best practices for Ansible automation and includes:

- Well-structured playbook organization
- Comprehensive inventory management
- Ansible configuration optimized for performance
- Documentation and testing frameworks

## Requirements

- Ansible >= ${{ values.ansible_version }}
- Target systems: ${{ values.target_os }}
{%- if values.collections %}
- Required collections:
{%- for collection in values.collections %}
  - {{ collection }}
{%- endfor %}
{%- endif %}

## Quick Start

1. **Install dependencies:**
   ```bash
   {%- if values.galaxy_requirements %}
   ansible-galaxy install -r requirements.yml
   {%- endif %}
   ansible-galaxy collection install {{ values.collections | join(' ') }}
   ```

2. **Update inventory:**
   Edit `inventory/hosts` to match your infrastructure

3. **Run the playbook:**
   ```bash
   ansible-playbook -i inventory/hosts playbook.yml
   ```

## Project Structure

```
${{ values.name }}/
├── playbook.yml           # Main playbook
├── ansible.cfg            # Ansible configuration
├── inventory/
│   └── hosts              # Inventory file
{%- if values.galaxy_requirements %}
├── requirements.yml       # Galaxy dependencies
{%- endif %}
├── group_vars/            # Group variables
├── host_vars/             # Host variables
├── roles/                 # Custom roles
{%- if values.molecule_testing %}
├── molecule/              # Molecule testing
{%- endif %}
└── README.md              # This file
```

## Configuration

### Inventory Management

The inventory is located in `inventory/hosts`. Update it with your target hosts:

```ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com
```

### Variables

- **Group variables:** Place in `group_vars/`
- **Host variables:** Place in `host_vars/`
- **Playbook variables:** Defined in `playbook.yml`

### Ansible Configuration

Key settings in `ansible.cfg`:
- Parallel execution (forks: 50)
- Smart gathering for performance
- Comprehensive logging
- SSH optimization

## Usage Examples

### Basic execution:
```bash
ansible-playbook playbook.yml
```

### With specific inventory:
```bash
ansible-playbook -i inventory/production playbook.yml
```

### Limit to specific hosts:
```bash
ansible-playbook playbook.yml --limit webservers
```

### Check mode (dry run):
```bash
ansible-playbook playbook.yml --check
```

### With tags:
```bash
ansible-playbook playbook.yml --tags "setup,configure"
```

## Testing

{%- if values.molecule_testing %}
This project includes Molecule for testing:

```bash
# Install molecule
pip install molecule[docker]

# Run tests
molecule test
```
{%- else %}
Testing can be done using:

1. **Check mode:** `ansible-playbook playbook.yml --check`
2. **Syntax check:** `ansible-playbook playbook.yml --syntax-check`
3. **Linting:** `ansible-lint playbook.yml`
{%- endif %}

## Best Practices

1. **Use descriptive task names**
2. **Implement proper error handling**
3. **Use handlers for service restarts**
4. **Tag tasks appropriately**
5. **Document variables and their purposes**
6. **Test in staging before production**

## Security Considerations

- Store sensitive data in Ansible Vault
- Use least privilege principles
- Regularly update dependencies
- Validate input parameters
- Use secure connection methods

## Troubleshooting

### Common Issues

1. **Connection failures:**
   - Verify SSH connectivity
   - Check inventory hostnames
   - Validate SSH keys

2. **Permission errors:**
   - Ensure proper sudo configuration
   - Check file permissions
   - Verify user privileges

3. **Module failures:**
   - Update Ansible version
   - Install required collections
   - Check module documentation

### Debug Mode

Run with increased verbosity:
```bash
ansible-playbook playbook.yml -vvv
```

## Contributing

1. Follow Ansible best practices
2. Test changes thoroughly
3. Update documentation
4. Use descriptive commit messages

## Support

- **Documentation:** [Ansible Documentation](https://docs.ansible.com/)
- **Community:** [Ansible Forum](https://forum.ansible.com/)
- **Issues:** [Project Issues](https://github.com/${{ values.destination.owner }}/${{ values.destination.repo }}/issues)

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

---

Generated with ❤️ by AWX Backstage Platform
