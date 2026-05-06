defmodule MiniDiscord.Client do

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
  def start(host, port) do
    connect_with_retry(host, port, 1)
  end
  defp connect_with_retry(host, port, attempt) do
    case :gen_tcp.connect(host,port,[:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        rencontre(socket)
        receiver=Task.async(fn -> receive_loop(socket, host, port) end)
        sender=Task.async(fn -> send_loop(socket) end)
        Task.await(receiver,:infinity)
        Task.await(sender,:infinity)
      {:error, reason} ->
        IO.write("Tentative #{attempt} échouée : #{reason}")
        :timer.sleep(2000)
        connect_with_retry(host, port, attempt + 1)
    end
  end

  defp rencontre(socket) do
    recv_print(socket)
    pseudo=IO.gets("Pseudo ?\n")
    :gen_tcp.send(socket,pseudo)

    recv_print(socket)
    salon=IO.gets("Nom salon ?\n")
    :gen_tcp.send(socket,salon)

    recv_print(socket)
  end

  defp recv_print(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} -> IO.write(msg)
      {:error, _} -> IO.puts("Erreur réception")
    end
  end

  defp receive_loop(socket, host, port) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, msg} ->
        IO.write(msg)
        receive_loop(socket, host, port)
      {:error,reason} ->
        IO.puts("\nConnexion perdue (#{reason}). Reconnexion...")
        :gen_tcp.close(socket)
        connect_with_retry(host, port, 1)
    end
  end

  defp send_loop(socket) do
    paquet=IO.gets("")
    case valider_message(paquet) do
      {:error, reason} -> reason
      {:ok, msg} ->
        :gen_tcp.send(socket,paquet)
        send_loop(socket)
    end
  end

  defp valider_message(msg) do
    if msg=="" do
      {:error, "Message vide"}
    end
    if String.length msg >= 500 do
      {:error, "Message trop long (max 500 chars)"}
    end
    if String.contains? msg,["/","?", "<", ">"] do
      {:error, "Caractère interdit"}
    end
    {:ok, msg}
  end
end
