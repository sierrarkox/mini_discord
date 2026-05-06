defmodule MiniDiscord.ClientHandler do
  require Logger

  def start(socket) do
    :gen_tcp.send(socket, "Bienvenue sur MiniDiscord!\r\n")
    pseudo = choisir_pseudo(socket)
    :gen_tcp.send(socket, "Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, "Rejoins un salon (ex: general) : ")
    {:ok, salon} = :gen_tcp.recv(socket, 0)
    salon = String.trim(salon)

    rejoindre_salon(socket, pseudo, salon)
  end

  defp rejoindre_salon(socket, pseudo, salon) do
    case Registry.lookup(MiniDiscord.Registry, salon) do
      [] ->
        DynamicSupervisor.start_child(
          MiniDiscord.SalonSupervisor,
          {MiniDiscord.Salon, salon})
      _ -> :ok
    end

    MiniDiscord.Salon.rejoindre(salon, self())
    MiniDiscord.Salon.broadcast(salon, "📢 #{pseudo} a rejoint ##{salon}\r\n")
    :gen_tcp.send(socket, "Tu es dans ##{salon} — écris tes messages !\r\n")

    loop(socket, pseudo, salon)
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg} ->
        msg = String.trim(msg)
        if String.first(msg)=="/" do
          gerer_commande(socket, pseudo, salon, msg)
        else
          MiniDiscord.Salon.broadcast(salon, "[#{pseudo}] #{msg}\r\n")
        end
        loop(socket, pseudo, salon)

      {:error, :timeout} ->
        loop(socket, pseudo, salon)

      {:error, reason} ->
        Logger.info("Client déconnecté : #{inspect(reason)}")
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
    end
  end

  defp salons_dispo do
    case MiniDiscord.Salon.lister() do
      [] -> "aucun (tu seras le premier !)"
      salons -> Enum.join(salons, ", ")
    end
  end

  defp pseudo_disponible?(pseudo) do
    case :ets.lookup(:pseudos,pseudo) do
      [{^pseudo,pid}] -> false
      [] -> true
    end
  end

  defp reserver_pseudo(pseudo) do
    :ets.insert(:pseudos, {pseudo, self()})
  end

  defp liberer_pseudo(pseudo) do
    :ets.delete(:pseudos, pseudo)
  end

  defp choisir_pseudo(socket) do
    :gen_tcp.send(socket, "Entre ton pseudo : ")
    {:ok, pseudo} = :gen_tcp.recv(socket, 0)
    pseudo = String.trim(pseudo)
    if pseudo_disponible?(pseudo) do
      reserver_pseudo(pseudo)
      pseudo
    else
      :gen_tcp.send(socket, "Pseudo déjà utilisé : veuillez en choisir un autre\r\n")
      choisir_pseudo(socket)
    end
  end

  defp gerer_commande(socket, pseudo, salon, commande) do

    case String.slice(commande,0..4) do

      "/list" ->
        salons = MiniDiscord.Salon.lister()

        msg =
          case salons do
            [] -> "Aucun salon disponible\r\n"
            _ -> "Salons: " <> Enum.join(salons, ", ") <> "\r\n"
          end

        :gen_tcp.send(socket, msg)

      "/join" ->
        MiniDiscord.Salon.quitter(salon,self())
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        rejoindre_salon(socket, pseudo, String.slice(commande,6..-1))
      "/quit" ->
        MiniDiscord.Salon.quitter(salon,self())
        liberer_pseudo(pseudo)
        :gen_tcp.send(socket, "Déconnexion...\r\n")
        :gen_tcp.close(socket)
      _ -> :gen_tcp.send(socket, "Commande inconnue\r\n")
    end
  end
end
