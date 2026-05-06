defmodule MiniDiscord.Client do

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
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
      # TODO : Connecter la socket avec :gen_tcp.connect/3
      # TODO : Options : [:binary, packet: :line, active: false]
      # TODO : En cas d'erreur {:error, reason} -> afficher l'erreur et quitter
      # TODO : Appeler la fonction rencontre(socket) pour le pseudo et le salon
      # TODO : Lancer le receiver dans un Task.async : fn -> receive_loop(socket) end
      # TODO : Lancer le sender dans un Task.async : fn -> send_loop(socket) end
      # TODO : Attendre les deux tasks avec Task.await/2 (timeout: :infinity)
  end

  defp rencontre(socket) do
    recv_print(socket)
    pseudo=IO.gets("Pseudo ?\n")
    :gen_tcp.send(socket,pseudo)

    recv_print(socket)
    salon=IO.gets("Nom salon ?\n")
    :gen_tcp.send(socket,salon)

    recv_print(socket)
      # TODO : Lire les messages du serveur avec recv_print(socket)
      # TODO : Envoyer le pseudo choisi par l'utilisateur avec IO.gets/1
      # TODO : Lire la suite (liste des salons)
      # TODO : Envoyer le nom du salon
      # TODO : Lire la confirmation
  end

  defp recv_print(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} -> IO.write(msg)
      {:error, _} -> IO.puts("Erreur réception")
    end
  end

  defp receive_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} ->
        IO.write(msg)
        receive_loop(socket)
      {:error,_} ->
        IO.write("Déconnecté")
        :gen_tcp.shutdown(socket, 0)
      # TODO : Appeler :gen_tcp.recv(socket, 0) — bloquant jusqu'à réception
      # TODO : Si {:ok, msg} -> afficher avec IO.write/1 et rappeler receive_loop
      # TODO : Si {:error, _} -> afficher "Déconnecté" et arrêter
    end
  end

  defp send_loop(socket) do
    paquet=IO.gets("")
    :gen_tcp.send(socket,paquet)
    send_loop(socket)
      # TODO : Lire depuis le clavier avec IO.gets("")
      # TODO : Envoyer au serveur avec :gen_tcp.send/2
      # TODO : Rappeler send_loop(socket)
  end

end
