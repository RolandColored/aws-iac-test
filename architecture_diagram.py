from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import Aurora
from diagrams.aws.network import APIGateway
from diagrams.aws.network import Route53

tenants = ["Bessie", "Clarabelle", "Penelope"]

with Diagram("Multi-tenant server infrastructure", show=False):
    dns = Route53("dns")
    api = APIGateway("api")
    dns >> Edge(label="*.example.com") >> api

    for tenant in tenants:
        with Cluster(tenant):
            tenant_server = Lambda("server")
            tenant_database = Aurora("database")
            api >> Edge(label=f"{tenant.lower()}.example.com") >> tenant_server >> tenant_database

