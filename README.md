# Multi-tenant AWS infrastructure
An implementation for a small exercise on Terraform and AWS.

## Infrastructure architecture
![Infrastructure architecture](multi-tenant_server_infrastructure.png)

## ToDos
- In which network(s) do the resources reside?
- Code
- Benefits/Risks table

## Questions on requirements
- What kind of application will be hosted? Web App, mobile App backend, somehing completely different?
- Which tech stack uses the server? Is Dockerization suitable?
- Is scaling an issue? How many users are expected and how computation intense is the application?
- How is the data structured and how is it accessed? Is it more relational and OLTP or OLAP? Or could something else (Key value, Document, ...) be an option?
