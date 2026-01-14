# orchestration


### usando o docker compose

Abre um terminal na pasta orchestration

build todos os projetos e bancos

```
docker-compose up --build
```

depois que fez o build uma vez só rodar  o up

```
docker-compose up
```

para e deleta todos os containers

```
docker-compose down -v
```

-----------------

## Utilizando os bash files

para subir os containers

```
./startall.sh
```

parar e remover os containers

```
./downall.sh
```

--------------------

### Estrutura de pastas dos projetos gits


```
capucheta/
├── catalogapi/
├── notificationsapi/
├── orchestration/
└── paymentsapi/
└── usersapi/
```

------------------

Miro com um workflow basico para gui

https://miro.com/app/board/uXjVJ-g_ni8=/?share_link_id=452428393845
