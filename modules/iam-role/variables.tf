variable "role_name" {
  description = "role_name"
  type        = string
}

variable "role_path" {
  description = "role_path"
  type        = string
}

variable "stmts" {
  description = "role statements"
  type = map(object({
    sid       = optional(string)
    effect    = optional(string)
    actions   = list(string)
    resources = optional(list(string))
    principals = optional(map(object({
      type        = string
      identifiers = list(string)
    })))
    condition = optional(map(object({
      test     = optional(string)
      variable = optional(string)
      values   = optional(list(string))
    })))
  }))
}
