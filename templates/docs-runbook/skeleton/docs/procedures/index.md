# Operational Procedures

This section contains standard operational procedures for ${{ values.serviceName }}.

## Procedure Index

| Procedure                   | Description                  | Frequency |
| --------------------------- | ---------------------------- | --------- |
| [Deployment](deployment.md) | Deploy new versions          | As needed |
| [Rollback](rollback.md)     | Rollback to previous version | Emergency |
| [Scaling](scaling.md)       | Scale service up or down     | As needed |

## Before Running Any Procedure

1. **Verify you have the necessary access**
2. **Communicate in the appropriate channel**
3. **Have a rollback plan ready**
4. **Know when to escalate**

## Standard Maintenance Windows

| Environment | Window             | Notification    |
| ----------- | ------------------ | --------------- |
| Production  | Tue/Thu 2-4 AM UTC | 24 hours notice |
| Staging     | Any time           | 1 hour notice   |
| Development | Any time           | None required   |

## Change Management

For production changes:

1. Create a change request ticket
2. Get approval from team lead
3. Schedule during maintenance window
4. Notify stakeholders
5. Execute the change
6. Verify and document

## Emergency Changes

For emergency production changes:

1. Get verbal approval from on-call manager
2. Document actions in #incidents
3. Execute the change
4. Create retrospective ticket
5. Follow up with proper change request
