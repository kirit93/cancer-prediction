data "aws_caller_identity" "current" {}

resource "aws_instance" "melanoma_instance" {
    ami                     = data.aws_ami.latest-ubuntu.id
    instance_type           = var.instance_type
    subnet_id               = "subnet-f4e2659d"
    iam_instance_profile    = aws_iam_instance_profile.s3_instance_profile.name

    key_name                = "kirit-key" # aws_key_pair.deployer.key_name
    vpc_security_group_ids  = ["sg-26d9434f"]

    user_data = "${file("../../sources/ec2/scripts/install_anaconda.sh")}"

    tags = {
        Name = "${var.namespace}-compute-instance"
    }
}

resource "aws_instance" "preprocessing_instance" {
    ami                     = data.aws_ami.latest-ubuntu.id
    instance_type           = var.instance_type
    subnet_id               = "subnet-f4e2659d"
    iam_instance_profile    = aws_iam_instance_profile.s3_instance_profile.name

    key_name                = "kirit-key" # aws_key_pair.deployer.key_name
    vpc_security_group_ids  = ["sg-26d9434f"]

    tags = {
        Name = "${var.namespace}-preprocessing-instance"
    }
}

resource "aws_ebs_volume" "melanoma_vol" {
    availability_zone = "us-east-2a"
    size = 50
    encrypted = true
    tags = {
        Name = "${var.namespace}-volume-1"
    }
}

resource "aws_ebs_volume" "preprocessing_vol" {
    availability_zone = "us-east-2a"
    size = 50
    encrypted = true
    tags = {
        Name = "${var.namespace}-volume-2"
    }
}

resource "aws_volume_attachment" "melanoma_attachment" {
    device_name = "/dev/sdf"
    volume_id = aws_ebs_volume.melanoma_vol.id
    instance_id = aws_instance.melanoma_instance.id
}

resource "aws_volume_attachment" "preprocessing_attachment" {
    device_name = "/dev/sdf"
    volume_id = aws_ebs_volume.preprocessing_vol.id
    instance_id = aws_instance.preprocessing_instance.id
}

# resource "aws_key_pair" "deployer" {
#   key_name   = "deployer-key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC2ptzjB3sc6vo1FfdmL9TsPURS3I9RGe6vXlYzmjCmptGHB578TSOxMXP0osTrbsxyr1jrJOJ+bP6Mr4B4AWp6Lwsu+fvTqLLqMkhC12/WiJ4LXKye710DJHZBr386NcsoOr3q0i16+Q/fIo/yJKu3Dmt/RBOj2edjk/MQ1qhaTgMgTfF8sL3Htjiyaz5GGkEay+u4cw+wTB0XCpkCj6yruHruq05Xo37OSGC5ALxSyJYdISLBCXYQLM5y/4HpdOs9vensx+QwOcgNmBNA5cx3ytoAoskd2upDIYFunhBnJVLNqpzaqrtWT/+jhUVYexQQ8S4Xdk4GzC0dloHz3GFQqxB98W53k92FLpSca8IxkmJEQDPPysQtM1/A79At3eYpQsHWX03Q8zAn0EYhcWkJ2h1SphTkYb1NI7fXKpEP+Jta/L/+lHBbs+lNsyYCwnfvzMMskdlM7v7B2jxrkvlRh/NsE/KIjAe73RpI8MZkwnbYFy/D6IZREBuXA0S8Hbk= kirit.thadaka@slalom.com"
# }

data "aws_ami" "latest-ubuntu" {
    most_recent = true
    owners = ["099720109477"] # Canonical

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }
}

# resource "aws_security_group" "ec2_sg" {
#   name        = "allow_tls"
#   description = "Allow SSH from the Bastion Server"
#   vpc_id      = var.vpc

#   ingress {
#     # TLS (change to whatever ports you need)
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     security_groups = ["sg-66d9fe0d"]
#   }

#   egress {
#     from_port       = 0
#     to_port         = 0
#     protocol        = "-1"
#     cidr_blocks     = ["0.0.0.0/0"]
#   }
# }

data "aws_iam_policy_document" "instance-assume-role-policy" {
    statement {
    actions = ["sts:AssumeRole"]

    principals {
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
    }
}
}

resource "aws_iam_role" "ec2_role" {
    name = "${var.namespace}-ec2-policy"
    assume_role_policy = data.aws_iam_policy_document.instance-assume-role-policy.json
}

resource "aws_iam_policy" "s3_policy" {
    name        = "${var.namespace}-s3-policy"
    description = "Read S3"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:*"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ssm" {
    name        = "${var.namespace}-ssm-policy"
    description = "SSM Params"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ssm:PutParameter",
                "ssm:GetParameter"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "cloudwatch" {
    name        = "${var.namespace}-cloudwatch-policy"
    description = "SSM Params"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:CreateLogStream",
                "logs:CreateLogGroup",
                "logs:PutLogEvents"
            ],
            "Effect": "Allow",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecr" {
    name        = "${var.namespace}-ecr-policy"
    description = "ECR Policy"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:*"
            ],
        "Effect": "Allow",
        "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "kms" {
    name        = "${var.namespace}-kms-policy"
    description = "kms Policy"

    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "ecr:*"
            ],
        "Effect": "Allow",
        "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach-s3-role" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "attach-ssm-role" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.ssm.arn
}

resource "aws_iam_role_policy_attachment" "attach-cloudwatch-role" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.cloudwatch.arn
}

resource "aws_iam_role_policy_attachment" "attach-ecr-role" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.ecr.arn
}

resource "aws_iam_role_policy_attachment" "attach-kms-role" {
    role       = aws_iam_role.ec2_role.name
    policy_arn = aws_iam_policy.kms.arn
}

resource "aws_iam_instance_profile" "s3_instance_profile" {
    name = "${var.namespace}-instance-profile"
    role = aws_iam_role.ec2_role.name
}