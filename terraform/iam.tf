resource "aws_iam_role" "this" {
  name               = var.resource_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
}

resource "aws_iam_instance_profile" "this" {
  name = var.resource_name
  role = aws_iam_role.this.name
}

resource "aws_iam_policy" "this" {
  name = var.resource_name
  path = "/"

  policy = data.aws_iam_policy_document.permission_policy.json
}

resource "aws_iam_role_policy_attachment" "custom" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}