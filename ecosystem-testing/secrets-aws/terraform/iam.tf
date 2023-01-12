//--------------------------------------------------------------------
// Resources

resource "aws_iam_user" "federation_token" {
    name = "${var.environment_name}-federation_token-user"
}

resource "aws_iam_access_key" "federation_token" {
    user = aws_iam_user.federation_token.name
}

resource "aws_iam_user_policy" "federation_token" {
    name = "${var.environment_name}-federation_token-user-policy"
    user = aws_iam_user.federation_token.name

    policy = data.aws_iam_policy_document.federation_token.json
}

resource "aws_iam_user_policy_attachment" "ec2-readonly-attach" {
  user       = aws_iam_user.federation_token.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# resource "aws_iam_role" "federation_token" {
#   name               = "${var.environment_name}-federation_token-role"
#   assume_role_policy = data.aws_iam_policy_document.assume_role.json
# }

# resource "aws_iam_role_policy" "federation_token" {
#   name   = "${var.environment_name}-federation_token-policy"
#   role   = aws_iam_role.federation.id
#   policy = data.aws_iam_policy_document.federation_token.json
# }

//--------------------------------------------------------------------
// Data Sources

# data "aws_iam_policy_document" "assume_role" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["ec2.amazonaws.com"]
#     }
#   }
# }

data "aws_iam_policy_document" "federation_token" {
  statement {
    sid    = "GetFederationToken"
    effect = "Allow"

    actions = ["sts:GetFederationToken"]

    resources = ["*"]
  }

  statement {
    sid    = "selfIAM"
    effect = "Allow"
    actions = [
      "iam:*"
    ]
    resources = [
      aws_iam_user.federation_token.arn
    ]
  }
}

