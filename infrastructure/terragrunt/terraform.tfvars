terragrunt = {
  # Configure Terragrunt to use DynamoDB for locking
  lock {
    backend = "dynamodb"
    config {
      state_file_id = "${path_relative_to_include()}"
      aws_region = "${get_env("TF_VAR_global_region", "us-east-1")}"
      table_name = "${get_env("TF_VAR_dynamo_db_terragrunt_locks", "")}"
    }
  }

  # Configure Terragrunt to automatically store tfstate files in an S3 bucket
  remote_state {
    backend = "s3"
    config {
      encrypt = "true"
      bucket = "${get_env("TF_VAR_remote_state_bucket", "")}"
      key = "${path_relative_to_include()}/${get_env("TF_VAR_remote_state_key", "")}"
      region = "${get_env("TF_VAR_global_region", "us-east-1")}"
    }
  }
}
