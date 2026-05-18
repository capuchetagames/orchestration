# 🚀 Guia de Implantação e Destruição da Infraestrutura (AWS EKS)

Este documento descreve o processo passo a passo para levantar e destruir toda a arquitetura de microsserviços do projeto **PosFiap** utilizando o AWS Academy. O objetivo principal é garantir o funcionamento das APIs e evitar o consumo desnecessário de créditos quando o sistema não estiver em uso.

---

## 🏗️ 1. Subindo o Cluster Kubernetes (Deploy)

A infraestrutura foi configurada para ser executada no serviço EKS (Elastic Kubernetes Service) da Amazon, utilizando instâncias `t3.medium` compatíveis com o AWS Academy e utilizando a `LabRole`.

**Passo a passo:**
1. Abra o terminal na raiz do projeto (onde está o arquivo `eks-cluster.yaml`).
2. Execute o comando de criação do cluster:
   ```bash
   eksctl create cluster -f eks-cluster.yaml
   ```
   *(Atenção: A criação de um cluster EKS do zero e o provisionamento dos nós EC2 geralmente leva de 15 a 20 minutos).*

---

## ⚙️ 2. Fazendo o Deploy dos Microsserviços

Assim que o cluster estiver `Ready`, precisamos aplicar os arquivos de configuração (manifestos) do Kubernetes para levantar os Bancos de Dados, RabbitMQ e nossas 4 APIs (Users, Catalog, Payments e Notifications).

**Opção A: Deploy Automático (CI/CD)**
Se você configurou os *Secrets* no GitHub, basta fazer um commit na branch `main` de cada repositório e as pipelines do GitHub Actions farão o push e o rollout automático de todas as imagens.

**Opção B: Deploy Manual (Script Local)**
Se preferir rodar manualmente a partir do seu terminal:
1. Acesse a pasta `orchestration`:
   ```bash
   cd orchestration/k8s
   ```
2. Execute o script de inicialização total:
   ```bash
   ./start-all.sh
   ```
3. Acompanhe a subida dos pods com o comando:
   ```bash
   kubectl get pods -n fiapstore -w
   ```

---

## 🌐 3. Acessando as APIs na Nuvem

O EKS provisiona os **AWS Classic Load Balancers** automaticamente para expor os serviços. Para pegar as URLs de acesso público:

```bash
kubectl get svc -n fiapstore
```
Localize a coluna **EXTERNAL-IP** dos serviços terminados em `-api` (ex: `users-api`). 

**Exemplo de Acesso via Postman / Browser:**
```text
http://<EXTERNAL-IP-DO-LOADBALANCER>:8080/health
```
*(Nota: Sempre inclua a porta `:8080` ao acessar o Load Balancer).*

---

## 🗑️ 4. Destruindo a Infraestrutura (Save Credits!)

Para não torrar os $50 dólares do AWS Academy, **sempre destrua a infraestrutura** após terminar as apresentações ou testes. 

**Para deletar o Cluster inteiro (incluindo Nós, Redes e Load Balancers):**
Execute na raiz do projeto:
```bash
eksctl delete cluster --name cluster-fiapstore --region us-east-1
```
*(Esse comando demora cerca de 10 minutos para deletar com segurança todos os recursos. Você pode fechar o terminal após a conclusão com sucesso).*

> **Aviso sobre a Lambda:** 
> O serviço de envio de e-mails (`EmailSenderLambda`) está hospedado via arquitetura *Serverless* e possui cobrança por uso. Como ele custa zero dólares enquanto não estiver processando envios, **não é necessário apagar a Lambda.**

---

## 🛠️ 5. Resolução de Problemas (Troubleshooting)

### Erro ao Recriar: `AlreadyExistsException: Stack [eksctl-cluster-fiapstore-cluster] already exists`
Esse erro acontece ao tentar criar o cluster caso a exclusão anterior tenha falhado parcialmente (o cluster EKS em si foi apagado, mas a stack do CloudFormation correspondente ficou "travada" com status `DELETE_FAILED`).

**Solução:**
Force a exclusão da stack residual via AWS CLI executando:
```bash
aws cloudformation delete-stack --stack-name eksctl-cluster-fiapstore-cluster --region us-east-1
```
Aguarde alguns segundos e, em seguida, você poderá rodar o comando de criação `eksctl create cluster -f eks-cluster.yaml` normalmente.

