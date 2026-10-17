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
    key_schema {
      attribute_name = "userID"
      key_type       = "HASH"
    }
    name               = "user-id-index"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }

  global_secondary_index {
    key_schema {
      attribute_name = "time"
      key_type       = "HASH"
    }
    name               = "alarm-time-index"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }

  global_secondary_index {
    key_schema {
      attribute_name = "target"
      key_type       = "HASH"
    }
    name               = "target-index"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 1
    write_capacity     = 1
  }
}

# キャラの数は少ないが項目が大きくなりやすい (設定・リソース) ので、容量を気にしなくてよいオンデマンドにする
resource "aws_dynamodb_table" "chara_table" {
  name           = "chara-table"
  hash_key       = "charaID"
  billing_mode   = "PAY_PER_REQUEST"
  stream_enabled = false

  attribute {
    name = "charaID"
    type = "S"
  }
}

# トップでキャラをタップしたときのセリフ。言語 × テーマで数が増えるので、キャラの項目ではなく1行ずつ置く
resource "aws_dynamodb_table" "chara_tap_line_table" {
  name           = "chara-tap-line-table"
  hash_key       = "charaID"
  range_key      = "lineID"
  billing_mode   = "PAY_PER_REQUEST"
  stream_enabled = false

  attribute {
    name = "charaID"
    type = "S"
  }

  attribute {
    name = "lineID"
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
