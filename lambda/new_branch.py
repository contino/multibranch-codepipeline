import boto3
import json

codepipeline_client = boto3.client('codepipeline')

def new_branch(event, context):

    branch_ref = event['Records'][0]['codecommit']['references'][0]['ref'].split("/")
    
    new_branch = branch_ref[-1]

    try:
        reference_pipeline = codepipeline_client.get_pipeline(name='test-trigger-REFERENCE-branch-pipeline')
    except:
        print("Reference pipeline is not available.")

    stage, = [ s for s in reference_pipeline['pipeline']['stages'] if s['name'] == 'Source' ]

    stage['actions'][0]['configuration']['BranchName'] = new_branch
    
    reference_pipeline['pipeline']['name'] = 'test-trigger-branch-'+ new_branch +'-pipeline'

    modified_pipeline_json = reference_pipeline['pipeline']

    try:
        new_pipeline_response = codepipeline_client.create_pipeline(pipeline=modified_pipeline_json)
    except: 
        print("Unable to generate new pipeline.")
    
    return str(new_pipeline_response)