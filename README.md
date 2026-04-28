# mini_discord

## Phase 1

### 1.1
Q1) On utilise Process.monitor pour suivre la vie du processus avec le pid correspondant. Cela permet d'être prévenu quand le processus s'arrête.

Q2) Si on n'implémente pas handle_info({:DOWN, ...}), l'information de fin d'un processus envoyé par Process.monitor ne sera pas traité correctement et générera une erreur.

Q3) Le handle_call attend une réponse du serveur après lui avoir envoyer une requête(appel synchrone). Le handle_cast se contente d'envoyer une requête sans attendre de réponse(appel asynchrone). Le broadcast est un cast car il est utilisé pour envoyer les messages et ne nécessite donc pas d'attendre une réponse du serveur.


## Phase 2

2-4. Lorsque l'on tue le pid d'un salon, celui-ci exclue du salon tout les utilisateurs et redémarre. En relancant la commande "nc localhost 4040" on peut alors se reconnecter au salon. Le salon redémarre car dans le client_handler on le redèmarre avec start_child.

2-5. Lorsqu'un processus crash, la stratégie :one_for_one ne redémarre que le processus qui c'est arrété alors que la stratégie :one_for_all redémarre tout les processus si un seul des processus crash.