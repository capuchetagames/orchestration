# Orchestration - Microservices Management

## Descrição

Este repositório centraliza a **orquestração dos microsserviços** do ecossistema Capucheta, com suporte para:

- execução local com Docker Compose
- execução em ambiente AWS (variáveis `.env.aws`)
- deploy em Kubernetes/EKS
- observabilidade, mensageria e testes de carga

## Serviços e componentes atuais

### Microsserviços orquestrados

- `usersapi`
- `catalogapi`
- `paymentsapi`
- `notificationsapi`

### Infraestrutura compartilhada

- **RabbitMQ** (mensageria)
- **Kong + Konga** (API Gateway + UI de administração)
- **Redis** (utilizado no stack Kubernetes)
- **DynamoDB Local + DynamoDB Admin** (execução local)
- **LocalStack** (serviços AWS locais)
- **New Relic Infrastructure Agent** (monitoramento de host/containers)

Todos os serviços utilizam a rede Docker `app-network`.

## Estrutura do repositório

```text
orchestration/
├── docker-compose.local.yaml      # Orquestração local completa
├── docker-compose.aws.yaml        # Orquestração apontando para env AWS
├── startall.sh                    # Sobe os 4 microsserviços via compose de cada repo
├── downall.sh                     # Derruba os 4 microsserviços via compose de cada repo
├── rabbitmq/
├── kong/
├── kong-konga/
├── dynamo-local/
├── local-stack/
├── newrelic-infra/
├── k6/
└── k8s/
    ├── start-all.sh               # Deploy completo no namespace fiapstore
    ├── delete-all.sh              # Remove stack Kubernetes
    ├── build-and-push.sh          # Build/push multi-arquitetura das imagens
    ├── redis-deployment.yaml
    └── redis-service.yaml
```

## Pré-requisitos

- Docker + Docker Compose (v2)
- kubectl (para fluxo Kubernetes)
- eksctl (para criação/remoção de cluster EKS)
- k6 (opcional, para testes de carga)

## Organização dos repositórios

Os projetos devem ficar no mesmo diretório raiz:

```text
capucheta/
├── catalogapi/
├── notificationsapi/
├── orchestration/
├── paymentsapi/
└── usersapi/
```

Isso é necessário porque os arquivos de orquestração referenciam os outros repositórios com caminhos relativos (`../usersapi`, etc.).

## Execução com Docker Compose

### Ambiente local (recomendado para desenvolvimento)

```bash
docker compose -f docker-compose.local.yaml up -d
```

Para derrubar:

```bash
docker compose -f docker-compose.local.yaml down -v
```

Esse stack inclui RabbitMQ, Kong/Konga, DynamoDB local e os 4 microsserviços com `.env.local`.

### Ambiente AWS (variáveis `.env.aws`)

```bash
docker compose -f docker-compose.aws.yaml up -d
```

Para derrubar:

```bash
docker compose -f docker-compose.aws.yaml down -v
```

## Scripts auxiliares legados

Ainda disponíveis na raiz:

```bash
./startall.sh
./downall.sh
```

Esses scripts sobem/derrubam apenas os quatro microsserviços via `docker-compose` de cada repositório.

## Kubernetes / EKS

### Deploy completo

```bash
cd k8s
./start-all.sh
```

Fluxo atual do `start-all.sh`:

1. cria namespace `fiapstore`
2. aplica infraestrutura compartilhada (RabbitMQ + Redis)
3. cria/atualiza secrets a partir de variáveis do `.env` na raiz
4. aplica Deployments/Services/HPAs dos 4 microsserviços

### Remoção

```bash
cd k8s
./delete-all.sh
```

Para manter PVCs:

```bash
KEEP_PVC=true ./delete-all.sh
```

### Build e push de imagens

```bash
cd k8s
DOCKERHUB_USER=<seu-user> ./build-and-push.sh
```

## RabbitMQ

- AMQP: `5672`
- Management UI: `15672`
- usuário padrão: `admin`
- senha padrão: `admin`

> Altere credenciais padrão para produção em `rabbitmq/docker-compose.yaml`.

## Kong + Konga

Portas expostas no setup community (`kong-konga/docker-compose.yaml`):

- Kong Proxy: `8000` / `8443`
- Kong Admin API: `8001` / `8444`
- Kong Manager: `8002` / `8445`
- Konga UI: `1337`
- Postgres (Kong/Konga): `5432`

## Teste de carga (k6)

```bash
cd k6
k6 run index.js
```

Configuração atual: `10 VUs`, `30s`, endpoint `http://localhost:5200/Auth`.

## Referências

- [Guia de deploy e destruição da infraestrutura AWS/EKS](./README-DEPLOY.md)
- [Board Miro (workflow)](https://miro.com/app/board/uXjVJ-g_ni8=/?share_link_id=452428393845)
