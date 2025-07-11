/*----------------------------------------------------------------------*/
/* AWS Caller Identity (account_id, user_id, arn)                       */
/*----------------------------------------------------------------------*/
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}