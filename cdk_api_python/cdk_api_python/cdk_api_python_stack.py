from aws_cdk import ( 
    core as cdk,
    aws_lambda as _lambda,
    aws_apigateway as apigw,
    aws_dynamodb as ddb,
)

# For consistency with other languages, `cdk` is the preferred import name for
# the CDK's core module.  The following line also imports it as `core` for use
# with examples from the CDK Developer's Guide, which are in the process of
# being updated to use `cdk`.  You may delete this import if you don't need it.
from aws_cdk import core

class CdkApiPythonStack(cdk.Stack):

    def __init__(self, scope: cdk.Construct, construct_id: str, **kwargs) -> None:
        super().__init__(scope, construct_id, **kwargs)
        
        # Defines an AWS Dynamo table resource
        table = ddb.Table(
            self, 'Hits',
            partition_key={'name': 'millisec_epoch_time_stamp', 'type': ddb.AttributeType.NUMBER},
            sort_key={'name': 'path', 'type': ddb.AttributeType.STRING}
        )

        # create a global secondary index for query
        table.add_global_secondary_index(
            partition_key={'name': 'millisec_epoch_time_stamp', 'type': ddb.AttributeType.NUMBER},
            index_name='millisec_epoch_time_stamp'
        )

        # delete table if the infrastructure is deleted
        cfn_table = table.node.find_child("Resource")
        cfn_table.apply_removal_policy(cdk.RemovalPolicy.DESTROY)

        # Defines an AWS Lambda resource
        api_lambda = _lambda.Function(
            self, 'ApiHandler',
            runtime=_lambda.Runtime.PYTHON_3_7,
            code=_lambda.Code.from_asset('lambda_code'),
            handler='lambda_api.handler',
            environment={
                'HITS_TABLE_NAME': table.table_name,
            }
        )
        
        # Defines an AWS api gateway resource
        apigw.LambdaRestApi(
            self, 'ApiEndpoint',
            handler=api_lambda,
        )
        
        # granting read and write permissions for lambda over dynamo table
        table.grant_read_write_data(api_lambda)
        
        # defining the run time for lambda
        node_runtime = _lambda.Runtime('nodejs14.x')

        # Defines an AWS Lambda resource
        viewer_lambda = _lambda.Function(
            self, 'ViewerHandler',
            runtime=node_runtime,
            code=_lambda.Code.from_asset('viewer_lambda_code'),
            handler='index.handler',
            environment={
                'HITS_TABLE_NAME': table.table_name,
                'TITLE': 'Dynamo Viewer',
                'SORT_BY': '-millisec_epoch_time_stamp'
            }
        )

        # granting read permissions for lambda over dynamo table
        table.grant_read_data(viewer_lambda)

        # Defines an AWS api gateway resource
        apigw.LambdaRestApi(
            self, 'ViewerEndpoint',
            handler=viewer_lambda,
        )
        

