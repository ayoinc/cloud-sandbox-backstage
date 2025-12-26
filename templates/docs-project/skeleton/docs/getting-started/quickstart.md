# Quick Start

Get up and running with ${{ values.name }} in 5 minutes.

## Step 1: Configuration

Create a configuration file:

```yaml
# config.yaml
name: my-project
environment: development
```

## Step 2: Initialize

Run the initialization command:

```bash
# Initialize the project
<command> init

# Verify initialization
<command> status
```

## Step 3: Run

Start the application:

```bash
# Start in development mode
<command> start

# Or run in production
<command> start --production
```

## Step 4: Verify

Open your browser and navigate to:

```
http://localhost:3000
```

You should see the welcome page.

## What's Next?

Now that you have ${{ values.name }} running:

- Explore the [User Guide](../user-guide/introduction.md)
- Learn about [Features](../user-guide/features.md)
- Understand the [Architecture](../architecture/overview.md)

## Quick Reference

| Command            | Description        |
| ------------------ | ------------------ |
| `<command> init`   | Initialize project |
| `<command> start`  | Start application  |
| `<command> stop`   | Stop application   |
| `<command> status` | Check status       |
| `<command> help`   | Show help          |
