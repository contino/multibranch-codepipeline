import boto3
import json
from botocore.exceptions import ClientError

codecommit_client = boto3.client('codecommit')
codepipeline_client = boto3.client('codepipeline')

repository_name = 'trigger-test'

#pipeline name : trigger-test-pr-pr_id

def lambda_handler(event, context):

	openpr_list = codecommit_client.list_pull_requests(repositoryName=repository_name, pullRequestStatus='OPEN')
	open_pull_requests = openpr_list['pullRequestIds']

	for pr_id in open_pull_requests:
		pipeline_name = str(repository_name+"-"+"pr"+"-"+pr_id)
		try:
			pipeline_response = codepipeline_client.get_pipeline(name=pipeline_name)
		except ClientError as e:
			if e.response['Error']['Code'] == 'PipelineNotFoundException':
				print("Pipeline %s does not exist, creating a new one." % pipeline_name)

				pr_metadata = codecommit_client.get_pull_request(pullRequestId=pr_id)['pullRequest']['pullRequestTargets'][0]['sourceReference'].split("/")

				source_branch = pr_metadata[-1]

				try:
					reference_pipeline=codepipeline_client.get_pipeline(name='test-trigger-REFERENCE-pr-pipeline')
				except:
					print("Reference pipeline is not available.")

				stage, = [ s for s in reference_pipeline['pipeline']['stages'] if s['name'] == 'Source' ]
				stage['actions'][0]['configuration']['BranchName'] = source_branch
				reference_pipeline['pipeline']['name'] = 'test-trigger-pr-'+pr_id+'-pipeline'
				modified_pipeline_json = reference_pipeline['pipeline']

				try:
					new_pipeline_response = codepipeline_client.create_pipeline(pipeline=modified_pipeline_json)
				except:
					print("Unable to generate new pipeline.")
				else:
					print("Unexpected error: %s" % e)

	closedpr_list = codecommit_client.list_pull_requests(repositoryName=repository_name, pullRequestStatus='CLOSED')
	closed_pull_requests = closedpr_list['pullRequestIds']

	for pr_id in closed_pull_requests:
		pipeline_name = str('test-trigger-pr-'+pr_id+'-pipeline')
		try:
			pipeline_response = codepipeline_client.get_pipeline(name=pipeline_name)
			print("Cleaning up, deleting pipeline %s" % pipeline_name)
			codepipeline_client.delete_pipeline(name=pipeline_name)
		except ClientError as e:
			if e.response['Error']['Code'] == 'PipelineNotFoundException':
				print("Pipeline %s does not exist, nothing to do." % pipeline_name)
			else:
				print("Unexpected error: %s" % e)
