resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

# ---- Rôle 1 : la CI de app-demo peut envoyer des images dans ECR, rien d'autre ----
data "aws_iam_policy_document" "ci_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:elysenambinina@177919880/app-demo@1443511575:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_ci" {
  name               = "github-ci-app-demo"
  assume_role_policy = data.aws_iam_policy_document.ci_trust.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability", "ecr:InitiateLayerUpload", "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload", "ecr:PutImage", "ecr:BatchGetImage", "ecr:DescribeImages"
    ]
    resources = [aws_ecr_repository.app_demo.arn]
  }
}

resource "aws_iam_role_policy" "github_ci_ecr" {
  role   = aws_iam_role.github_ci.id
  policy = data.aws_iam_policy_document.ecr_push.json
}

# ---- Rôle 2 : infra-terraform peut LIRE le compte (plan, Conftest, détection des écarts) ----
data "aws_iam_policy_document" "readonly_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:elysenambinina@177919880/infra-terraform@1443511842:ref:refs/heads/main",
        "repo:elysenambinina@177919880/infra-terraform@1443511842:pull_request",
      ]
    }
  }
}

resource "aws_iam_role" "github_readonly" {
  name               = "github-infra-readonly"
  assume_role_policy = data.aws_iam_policy_document.readonly_trust.json
}

resource "aws_iam_role_policy_attachment" "github_readonly" {
  role       = aws_iam_role.github_readonly.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

output "github_ci_role_arn" { value = aws_iam_role.github_ci.arn }
output "github_readonly_role_arn" { value = aws_iam_role.github_readonly.arn }
