output "project_iam_member_ids" {
  description = "The IDs of the project IAM member resources"
  value = {
    for key, member in google_project_iam_member.project_bindings :
    key => member.id
  }
}

output "custom_role_ids" {
  description = "The IDs of the custom IAM roles"
  value = {
    for key, role in google_project_iam_custom_role.custom_roles :
    key => role.id
  }
}

output "custom_role_names" {
  description = "The fully qualified names of the custom IAM roles"
  value = {
    for key, role in google_project_iam_custom_role.custom_roles :
    key => role.name
  }
}

output "organization_iam_member_ids" {
  description = "The IDs of the organization IAM member resources"
  value = {
    for key, member in google_organization_iam_member.organization_bindings :
    key => member.id
  }
}

output "folder_iam_member_ids" {
  description = "The IDs of the folder IAM member resources"
  value = {
    for key, member in google_folder_iam_member.folder_bindings :
    key => member.id
  }
}
