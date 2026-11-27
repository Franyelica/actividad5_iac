# Estos valores se configuran como Variables del repositorio en GitHub.
output "tf_state_bucket" {
  description = "-> variable de GitHub TF_STATE_BUCKET"
  value       = aws_s3_bucket.state.id
}

output "plan_role_arn" {
  description = "-> variable de GitHub AWS_PLAN_ROLE_ARN"
  value       = aws_iam_role.plan.arn
}

output "apply_role_arn" {
  description = "-> variable de GitHub AWS_APPLY_ROLE_ARN"
  value       = aws_iam_role.apply.arn
}
