resource "aws_ecr_repository" "repository" {
  name = var.name
}

resource "aws_ecr_repository_policy" "repository_policy" {
  repository = aws_ecr_repository.repository.name
  policy     = data.aws_iam_policy_document.policy_document.json
}

data "aws_iam_policy_document" "policy_document" {
  statement {
    sid    = "allow-pull-statement"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        for account_id in var.allow_pull_account_ids :
        "arn:aws:iam::${account_id}:root"
      ]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:SetRepositoryPolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:DeleteRepositoryPolicy"
    ]
  }

  statement {
    sid    = "LambdaECRImageCrossAccountRetrievalPolicy"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
  }
}



# aws lambda add-permission \
# --statement-id "AllowCloudFrontServicePrincipal" \
# --action "lambda:InvokeFunctionUrl" \
# --principal "cloudfront.amazonaws.com" \
# --source-arn "arn:aws:cloudfront::039612872248:distribution/ELC6U7UET6QDF" \
# --region "ap-northeast-1" \
# --function-name <YOUR_FUNCTION_NAME>