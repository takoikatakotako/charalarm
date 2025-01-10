# DynamoDB
resource "aws_dynamodb_table" "user_table" {
  name           = "user-table"
  hash_key       = "userID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  stream_enabled = false

  attribute {
    name = "userID"
    type = "S"
  }
}

resource "aws_dynamodb_table" "alarm_table" {
  name           = "alarm-table"
  hash_key       = "alarmID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  stream_enabled = false

  attribute {
    name = "alarmID"
    type = "S"
  }

  attribute {
    name = "userID"
    type = "S"
  }

  attribute {
    name = "time"
    type = "S"
  }

  global_secondary_index {
    hash_key           = "userID"
    name               = "user-id-index"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }

  global_secondary_index {
    hash_key           = "time"
    name               = "alarm-time-index"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }
}

resource "aws_dynamodb_table" "chara_table" {
  name           = "chara-table"
  hash_key       = "charaID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  stream_enabled = false

  attribute {
    name = "charaID"
    type = "S"
  }
}






# TODO: オートスケーリングの設定

# resource "aws_appautoscaling_target" "alarm_table_read_autoscaling_target" {
#     max_capacity       = 10
#     min_capacity       = 1
#     resource_id        = "table/${aws_dynamodb_table.alarm_table.name}"
#     scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#     service_namespace  = "dynamodb"
# }

# resource "aws_appautoscaling_target" "alarm_table_write_autoscaling_target" {
#     max_capacity       = 10
#     min_capacity       = 1
#     resource_id        = "table/${aws_dynamodb_table.alarm_table.name}"
#     scalable_dimension = "dynamodb:table:ReadCapacityUnits"
#     service_namespace  = "dynamodb"
# }

# terraform import 

# service-namespace/resource-id/scalable-dimension

# dynamodb/table/alarm-table/dynamodb:table:ReadCapacityUnits
# dynamodb/table/alarm-table/dynamodb:table:WriteCapacityUnits


# service-namespace/resource-id/scalable-dimension

# dynamodb/table/alarm-table/dynamodb:table:ReadCapacityUnits

# aws application-autoscaling describe-scaling-policies  --service-namespace dynamodb --profile sandbox


# resource "aws_appautoscaling_policy" "dynamodb-test-table_read_policy" {
#     name               = "dynamodb-read-capacity-utilization-${aws_appautoscaling_target.dynamodb-test-table_read_target.resource_id}"
#     policy_type        = "TargetTrackingScaling"
#     resource_id        = "${aws_appautoscaling_target.dynamodb-test-table_read_target.resource_id}"
#     scalable_dimension = "${aws_appautoscaling_target.dynamodb-test-table_read_target.scalable_dimension}"
#     service_namespace  = "${aws_appautoscaling_target.dynamodb-test-table_read_target.service_namespace}"

#     target_tracking_scaling_policy_configuration {
#         predefined_metric_specification {
#             predefined_metric_type = "DynamoDBReadCapacityUtilization"
#         }
#         target_value = 70
#     }
# }
