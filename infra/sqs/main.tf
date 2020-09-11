resource "aws_sqs_queue" "terraform_queue" {
  name                      = "${var.namespace}-queue"
  delay_seconds             = 90
  max_message_size          = 4096
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
#   redrive_policy = jsonencode({
#     deadLetterTargetArn = aws_sqs_queue.terraform_queue_deadletter.arn
#     maxReceiveCount     = 4
#   })

    policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:*:*:s3-event-notification-queue",
      "Condition": {
        "ArnEquals": { "aws:SourceArn": "${var.bucketarn}" }
      }
    }
  ]
}
POLICY

}


resource "aws_s3_bucket_notification" "bucket_notification" {
    bucket = var.bucketid

    queue {
        queue_arn     = aws_sqs_queue.terraform_queue.arn
        events        = ["s3:ObjectCreated:*"]
        filter_suffix = ".png"
        filter_prefix = "tiled/"
    }
}