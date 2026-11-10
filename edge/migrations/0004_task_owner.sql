-- The task list shows a task's owner from spec.user.ref. Tasks whose spec
-- was replaced by the pipeline's lost it: the pipeline runs templates
-- without a user. Put back the user who created each of them.
UPDATE tasks
SET spec = json_set(spec, '$.user', json_object('ref', created_by))
WHERE json_extract(spec, '$.user.ref') IS NULL;
