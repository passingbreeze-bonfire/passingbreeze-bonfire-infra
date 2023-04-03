data "aws_iam_policy_document" "role-policy" {
  dynamic "statement" {
    iterator = statement
    for_each = var.stmts
    content {
      sid       = statement.value.sid
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "principals" {
        iterator = principal
        for_each = statement.value.principals
        content {
          type        = principal.value.type
          identifiers = principal.value.identifiers
        }
      }
      dynamic "condition" {
        iterator = condition
        for_each = statement.value.condition == null ? {} : statement.value.condition
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role" "this_role" {
  name               = var.role_name
  path               = var.role_path
  assume_role_policy = data.aws_iam_policy_document.role-policy.json
}
