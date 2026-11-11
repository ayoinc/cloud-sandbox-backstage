locals {
  # Segments are normalised so that a name never has empty or doubled parts.
  segments = {
    company = trim(replace(lower(var.company), "/[^a-z0-9]+/", "-"), "-")
    team    = trim(replace(lower(var.team), "/[^a-z0-9]+/", "-"), "-")
    project = trim(replace(lower(var.project), "/[^a-z0-9]+/", "-"), "-")
  }

  full = {
    for t in var.resource_types : t => (
      var.convention == "enterprise" ? join("-", [local.segments.company, local.segments.project, var.environment, t, var.instance]) :
      var.convention == "team" ? join("-", [local.segments.team, local.segments.project, t, var.environment, var.instance]) :
      join("-", [local.segments.project, t, var.environment, var.instance])
    )
  }

  # A name that exceeds a limit keeps its beginning and gets a hash of the
  # whole name, so that two long names never collapse into the same short one.
  hashes = { for t, name in local.full : t => substr(sha1(name), 0, 6) }

  standard = {
    for t, name in local.full : t => length(name) <= 63 ? name : "${trimsuffix(substr(name, 0, 56), "-")}-${local.hashes[t]}"
  }

  short = {
    for t, name in local.full : t => length(name) <= 24 ? name : "${trimsuffix(substr(name, 0, 17), "-")}-${local.hashes[t]}"
  }

  global = {
    for t, name in local.full : t => (
      length(name) + 1 + length(var.unique_suffix) <= 63
      ? "${name}-${var.unique_suffix}"
      : "${trimsuffix(substr(name, 0, 62 - 7 - length(var.unique_suffix)), "-")}-${local.hashes[t]}-${var.unique_suffix}"
    )
  }

  # The unique suffix already separates long names, so no hash is needed.
  global_short = {
    for t, name in local.full : t => (
      length(name) + 1 + length(var.unique_suffix) <= 30
      ? "${name}-${var.unique_suffix}"
      : "${trimsuffix(substr(name, 0, 29 - length(var.unique_suffix)), "-")}-${var.unique_suffix}"
    )
  }

  compact_full = { for t, name in local.full : t => replace(name, "-", "") }

  global_compact = {
    for t, name in local.compact_full : t => (
      length(name) + length(var.unique_suffix) <= 24
      ? "${name}${var.unique_suffix}"
      : "${substr(name, 0, 24 - 6 - length(var.unique_suffix))}${local.hashes[t]}${var.unique_suffix}"
    )
  }
}
