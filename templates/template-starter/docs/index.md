# Software Template

Creates a repository holding a software template of your own:

| In the repository    | What it is                                                   |
| -------------------- | ------------------------------------------------------------ |
| `template.yaml`      | The form people fill in and the steps that run               |
| `skeleton/`          | The files a new repository starts with                       |
| `sample-values.json` | Form values the check renders the template with              |
| `scripts/check.py`   | Finds the mistakes that otherwise show up in front of a user |

## From idea to the Create page

1. **Create** the repository with this template.
2. **Edit** `template.yaml` and `skeleton/`.
3. **Try it** in _Create > Template Editor_: load the repository's folder,
   fill the form, and see exactly which files it would write, without
   creating anything.
4. **Check**: every push runs `scripts/check.py`.
5. **Register** `template.yaml` at _Register a Component_. It appears in the
   Create page after the next catalog refresh.

The template is deliberately not registered when its repository is created:
a half-written template should not be offered to everyone.
