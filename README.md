# Terraform IaC para AWS - SREMack

Este repositório tem como objetivo mostrar como foi feito o trabalho individual final da disciplina de **Cloud Computing e SRE** do curso de **Engenharia de Dados** do Mackenzie.

Visão Geral da Arquitetura

## Descrição da Solução

Cada componente da solução tem uma função específica de entrega na arquitetura do projeto:

1. **VPC e Subnets**: Cria uma rede virtual privada com sub-redes, isolando os recursos e permitindo comunicação controlada.
2. **Internet Gateway e Route Table**: Permite a comunicação da VPC com a internet.
3. **Security Groups**: Define as regras de firewall para os recursos.
4. **API Gateway e Lambda**: Configura a API e funções sem servidor para responder às requisições.
5. **DynamoDB e RDS**: Cria bancos de dados para armazenar dados de forma estruturada e não estruturada.
6. **ECS Cluster e Service**: Orquestra contêineres para executar aplicações.
7. **ALB**: Balanceia o tráfego de entrada entre os contêineres.
8. **S3 Bucket**: Armazena arquivos e dados estáticos.

### Clonar o Repositório

\```git clone https://github.com/LariVicentin04/SREMack.git

`cd SREMack`

### Configurar o Ambiente AWS

\```aws configure```\


### Inicializar o Terraform

\```terraform init```\

### Planejar a Infraestrutura

\```terraform plan```\

### Aplicar a Infraestrutura

\```terraform apply```\

