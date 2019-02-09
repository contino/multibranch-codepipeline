# Multibranch/Multi pullrequest capable AWS CodePipeline + AWS CodeCommit implementation

![why u no](/docs/images/whyuno.jpg)

## Motivation

AWS CodePipeline supports only a single branch on any given pipeline. This is a major problem for developers and users who are used to popular CI tools. Several developers online have suggested and created workarounds but nothing really seemed straight-forward to me. I saw a stackoverflow post with less than three upvotes suggesting the approach I have taken and decided to implement it. The implementation itself has been quite challenging due to weird quirks with CodeCommit which have been described in detail below. I am yet to add CodeBuild configuration and setup stages.

## Challenges with CodeCommit (big oofs)

### CodeCommit cannot trigger targets if the events occur through the AWS console/CLI (may get fixed at some point)

CodeCommit initially looked like it can be setup easily to trigger the pipeline as intended and all these triggers can be managed using Terraform. The setup was simple and the console took care of setting up the permissions required to trigger the functions. After setting up and testing creation of a branch through the console, I realized that only branches created through the git client triggered the Lambda functions that create the pipeline for that branch. Git client seems to be the only way for now (Feb 2019).

https://forums.aws.amazon.com/message.jspa?messageID=852545

### Terraform cannot create more than one trigger on the CodeCommit repository (Provider issue)

If you have multiple triggers, terraform randomly chooses the lucky one and creates it.

https://github.com/terraform-providers/terraform-provider-aws/issues/3209

## Workaround

The only events we really care about are new branches and pull-requests. So I have decided to use that one precious trigger for triggering the branch pipeline creator Lambda function and utilize the SNS notification on pull-request events to trigger a Lambda function that handles pr pipeline creation. This can be easily changed to both functions being triggered by triggers when AWS fixes the Terraform issue.

#### New branch pipeline on branch creation flow

git client --> CodeCommit trigger --> Lambda Function

#### New pull request pipeline creation when a PR is opened

AWS Console --> Cloudwatch rule --> SNS topic --> Lambda function

Clearly this is not the most straight-forward setup but once you set this up, you can enjoy the luxurious pipeline features that come out of the box with popular CI tools. Moreover, this setup is completely configurable by modifying the lambda functions which is kinda cool and makes you feel extra nerdy I guess.

## Architecture

![architecture](/docs/images/architecture.png)


