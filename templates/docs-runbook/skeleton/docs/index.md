# ${{ values.name }}

${{ values.description }}

## Quick Links

| Category | Description |
|----------|-------------|
| [Incidents](incidents/index.md) | Response procedures for common incidents |
| [Procedures](procedures/index.md) | Standard operational procedures |
| [On-Call Guide](getting-started/oncall-guide.md) | Guide for on-call engineers |
| [Templates](templates/index.md) | Runbook templates |

## Service Overview

**Service**: ${{ values.serviceName }}

**Environments**: {% for env in values.environment %}{{ env }}{% if not loop.last %}, {% endif %}{% endfor %}

**On-Call Tool**: ${{ values.oncallTool }}

## Emergency Contacts

| Role | Contact |
|------|---------|
| On-Call Engineer | Check ${{ values.oncallTool }} |
| Team Lead | @team-lead |
| Escalation | #incident-response |

## How to Use This Runbook

1. **During an Incident**: Go directly to [Incidents](incidents/index.md)
2. **Routine Operations**: Check [Procedures](procedures/index.md)
3. **Starting On-Call**: Read [On-Call Guide](getting-started/oncall-guide.md)

## Contributing

To add or update a runbook:

1. Create a new markdown file in the appropriate directory
2. Follow the templates in [Templates](templates/index.md)
3. Submit a pull request for review
4. Ensure all commands are tested

## Last Updated

This documentation is maintained by ${{ values.owner }}.
