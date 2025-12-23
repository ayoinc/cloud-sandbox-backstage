# Runbook Templates

This section provides templates for creating new runbooks.

## Available Templates

| Template | Use Case |
|----------|----------|
| [Incident Template](#incident-template) | Responding to alerts and outages |
| [Procedure Template](#procedure-template) | Standard operational tasks |

## Incident Template

Use this template for incident response runbooks:

```markdown
# [Incident Name]

## Summary

Brief description of the incident type and what this runbook addresses.

## Symptoms

- Alert name and trigger conditions
- Observable symptoms
- User-reported issues

## Impact

- Severity level
- Affected users/systems
- Business impact

## Prerequisites

- Required access
- Tools needed
- Knowledge required

## Investigation Steps

### Step 1: [Name]

Description of what to do.

\`\`\`bash
# Command to run
command --with-options
\`\`\`

What to look for in the output.

### Step 2: [Name]

...

## Resolution Steps

### Option 1: [Name]

When to use this option.

\`\`\`bash
# Resolution command
\`\`\`

### Option 2: [Name]

...

## Verification

How to confirm the issue is resolved.

\`\`\`bash
# Verification command
\`\`\`

## Escalation

When to escalate and to whom.

## Prevention

Steps to prevent recurrence.
```

## Procedure Template

Use this template for operational procedures:

```markdown
# [Procedure Name]

## Summary

Brief description of the procedure and when to use it.

## Prerequisites

- [ ] Prerequisite 1
- [ ] Prerequisite 2

## Pre-Procedure Checklist

- [ ] Checklist item 1
- [ ] Checklist item 2

## Steps

### Step 1: [Name]

Description of what to do.

\`\`\`bash
# Command
\`\`\`

Expected outcome.

### Step 2: [Name]

...

## Verification

How to verify the procedure completed successfully.

## Post-Procedure

- [ ] Post-procedure action 1
- [ ] Post-procedure action 2

## Troubleshooting

Common issues and their solutions.

## Rollback

How to undo the procedure if needed.
```

## Best Practices

### Writing Good Runbooks

1. **Be Specific**: Include exact commands, not just concepts
2. **Copy-Paste Ready**: Commands should work when pasted
3. **Include Verification**: Always show how to confirm success
4. **Explain the Why**: Help readers understand, not just do
5. **Keep Updated**: Review runbooks after each use

### Formatting Guidelines

- Use headers to organize sections
- Use code blocks for commands
- Use tables for structured information
- Use admonitions for warnings/notes
- Include example output where helpful

### Testing Runbooks

- Test in staging before production
- Have another team member review
- Run through the procedure periodically
- Update based on real incident experience
