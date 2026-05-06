# mini_discord

## TP1
### Phase 1

#### 1.1
Q1) On utilise Process.monitor pour suivre la vie du processus avec le pid correspondant. Cela permet d'être prévenu quand le processus s'arrête.

Q2) Si on n'implémente pas handle_info({:DOWN, ...}), l'information de fin d'un processus envoyé par Process.monitor ne sera pas traité correctement et générera une erreur.

Q3) Le handle_call attend une réponse du serveur après lui avoir envoyer une requête(appel synchrone). Le handle_cast se contente d'envoyer une requête sans attendre de réponse(appel asynchrone). Le broadcast est un cast car il est utilisé pour envoyer les messages et ne nécessite donc pas d'attendre une réponse du serveur.


### Phase 2

2-4. Lorsque l'on tue le pid d'un salon, celui-ci exclue du salon tout les utilisateurs et redémarre. En relancant la commande "nc localhost 4040" on peut alors se reconnecter au salon. Le salon redémarre car dans le client_handler on le redèmarre avec start_child.

2-5. Lorsqu'un processus crash, la stratégie :one_for_one ne redémarre que le processus qui c'est arrété alors que la stratégie :one_for_all redémarre tout les processus si un seul des processus crash.


## TP2

### Fonction start du 1)
  def start(host, port) do
    case :gen_tcp.connect(host,port,[:binary, packet: :line, active: false]) do
      {:error, reason} -> reason
      {:ok,socket} ->
        rencontre(socket)
        receiver=Task.async(fn -> receive_loop(socket) end)
        sender=Task.async(fn -> send_loop(socket) end)
        Task.await(receiver,:infinity)
        Task.await(sender,:infinity)
    end
  end

### Fonction receive_loop du 1)
defp receive_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} ->
        IO.write(msg)
        receive_loop(socket)
      {:error,reason} ->
        IO.write("Déconnecté")
        :gen_tcp.shutdown(socket, 0)
    end
  end

### 2)
2.3