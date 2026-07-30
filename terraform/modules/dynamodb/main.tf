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

  attribute {
    name = "target"
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

  global_secondary_index {
    hash_key           = "target"
    name               = "target-index"
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

resource "aws_dynamodb_table" "news_table" {
  name           = "news-table"
  hash_key       = "newsID"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  stream_enabled = false

  attribute {
    name = "newsID"
    type = "S"
  }
}
