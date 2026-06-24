### S3 BOOTSTRAP BUCKET ###

module "bootstrap" {
  source = "github.com/PaloAltoNetworks/terraform-aws-swfw-modules//modules/bootstrap?ref=main"

  prefix      = "${var.name_prefix}${var.site_name}-"
  global_tags = var.global_tags

  iam_role_name             = "${var.name_prefix}${var.site_name}-vmseries"
  iam_instance_profile_name = "${var.name_prefix}${var.site_name}-vmseries-profile"

  bootstrap_options = merge(
    {
      hostname                    = "${var.name_prefix}${var.site_name}-fw"
      dns-primary                 = "169.254.169.253" # AWS VPC DNS
      dns-secondary               = "8.8.8.8"
      dhcp-send-hostname          = "yes"
      dhcp-send-client-id         = "yes"
      dhcp-accept-server-hostname = "yes"
      dhcp-accept-server-domain   = "yes"
    },
    var.bootstrap_options
  )
}

### IAM POLICY ###
# Allow VM-Series to publish CloudWatch metrics

data "aws_caller_identity" "this" {}
data "aws_partition" "this" {}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${var.name_prefix}${var.site_name}-cloudwatch"
  role = module.bootstrap.iam_role_name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "cloudwatch:PutMetricData",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = ["*"]
        Effect   = "Allow"
      },
      {
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DescribeAlarms"
        ]
        Resource = [
          "arn:${data.aws_partition.this.partition}:cloudwatch:*:${data.aws_caller_identity.this.account_id}:alarm:*"
        ]
        Effect = "Allow"
      }
    ]
  })
}
