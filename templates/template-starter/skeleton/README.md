# ${{ values.templateTitle }}

${{ values.description }}

A software template for the developer portal.

| File | What it is |
| --- | --- |
| `template.yaml` | The form people fill in and the steps that run |
| `skeleton/` | The files a new repository starts with |
| `sample-values.json` | Form values the check uses |
| `scripts/check.py` | The check |

## Work on it

1. Edit `template.yaml` and the files in `skeleton/`. In a skeleton file,
   `${{ "${{ values.name }}" }}` is replaced by what the form step passes as
   `name`.
2. Try it in the portal: **Create > Template Editor**, load this folder, fill
   the form. It shows the files it would write and creates nothing.
3. Run the check:

   ```bash
   uv run scripts/check.py
   ```

## What the check refuses

- A step that reads a form field the form does not have.
- A skeleton file that uses a value no step passes.
- `sample-values.json` missing a required field, or naming one the form does
  not have.
- A name, title, owner or step id that is missing or repeated.

## Publish it

Register `template.yaml` in the portal at **Register a Component**, with the
address of the file on GitHub. It appears in the Create page after the next
catalog refresh.
