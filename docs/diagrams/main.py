from diagrams import Cluster, Diagram
from diagrams.aws.database import RDS
from diagrams.aws.compute import LambdaFunction
from diagrams.aws.network import Route53
from diagrams.aws.storage import Backup
from diagrams.aws.storage import SimpleStorageServiceS3

graph_attr = {
  "bgcolor": "transparent",
  "pad": "0.5",
  "size": "6"
}

cluster_attr = {
  "bgcolor": "transparent",
  "pad": "0.5",
  "size": "6",
  "fontcolor": "#888888",
  "labeljust":"c"
}

node_attr = {
  "fontcolor": "#888888",
  "fontsize": "14pt"
}

with Diagram("", filename="main", show=False, direction="TB", graph_attr=graph_attr, node_attr=node_attr):
  
  with Cluster("Point in Time Recovery", graph_attr=cluster_attr):
            S3 = SimpleStorageServiceS3("S3")
            Backup = Backup("AWS Backup")

  with Cluster("Dump to S3", graph_attr=cluster_attr):
          Dump = LambdaFunction("db_dump")
          S3 = SimpleStorageServiceS3("S3")

  Reset     = LambdaFunction("db_reset")
  Management = LambdaFunction("db_user_managment")
  
  with Cluster("Restore from S3", graph_attr=cluster_attr):
            S3 = SimpleStorageServiceS3("S3")
            Restore = LambdaFunction("db_restore")

  Route53 = Route53("Route53")

  [ Backup,
    Route53    
  ]>> RDS("RDS") << [
          Reset,
          Restore,
          Dump,
          Management
        ]