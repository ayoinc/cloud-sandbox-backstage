# Runbook Documentation Template

This template creates operational runbooks for your services.

## Features

- **Structured format** - Consistent runbook layout
- **Incident response** - Step-by-step procedures
- **Troubleshooting** - Common issues and solutions
- **Escalation paths** - Contact information

## Runbook Structure

Each runbook should include:

1. **Overview** - Service description
2. **Architecture** - System components
3. **Health Checks** - How to verify service status
4. **Common Issues** - Known problems and fixes
5. **Escalation** - When and who to contact

## Quick Start

1. Create a new runbook from the template
2. Fill in service-specific information
3. Add troubleshooting procedures
4. Review with the team

## Template

```markdown
# Service Name Runbook

## Overview

Brief description of the service.

## Health Checks

- [ ] Check endpoint: `curl https://service/health`
- [ ] Verify logs: `kubectl logs -l app=service`

## Common Issues

### Issue: High latency

**Symptoms**: Response times > 500ms
**Resolution**:

1. Check database connections
2. Scale pods if needed

## Escalation

- L1: On-call engineer
- L2: Service owner
- L3: Platform team
```

## Support

Contact the SRE Team for assistance.
