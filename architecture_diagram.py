from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import Lambda
from diagrams.aws.database import RDSMysqlInstance
from diagrams.aws.network import APIGateway, VpnGateway, Route53
from diagrams.aws.general import User, Users

tenants = ["Bessie", "Clarabelle", "Penelope"]

with Diagram("Multi-tenant server infrastructure", show=False):
    dns = Route53("dns")
    api = APIGateway("api")
    users = Users("end users")
    admins = Users("db admins")

    users >> dns >> Edge(label="*.example.com") >> api

    for tenant in tenants:
        with Cluster(tenant):
            server = Lambda("server")
            with Cluster("VPC"):
                database = RDSMysqlInstance("database instance")
                proxy = VpnGateway("db proxy")  # there is no proxy icon, so we abuse this one
                proxy >> database

            api >> Edge(label=f"{tenant.lower()}.example.com") >> server >> proxy
            admins >> proxy

