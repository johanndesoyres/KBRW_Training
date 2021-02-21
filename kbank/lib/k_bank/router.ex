defmodule KBank.Router do
  use Plug.Router

  plug(Plug.Static, from: "priv/static", at: "/static")

  import Plug.Conn
  import Plug.BasicAuth

  plug(:basic_auth, username: "hello", password: "secret")
  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  def insert_accounts do
    accounts = [
      %{name: "de Soyres", first_name: "Johann", amt: 100},
      %{name: "Dupont", first_name: "Pierre", amt: 200},
      %{name: "Sarah", first_name: "Pinson", amt: 300}
    ]

    accounts |> Enum.map(fn val -> KBank.Account.create_account(KBank.Account, val) end)
  end

  get "/api/accounts" do
    if KBank.Account.is_empty(KBank.Account) do
      insert_accounts()
    end

    content =
      KBank.Account.get_all(KBank.Account)
      |> Enum.map(fn account ->
        Map.put(elem(account, 1), :accnt_nb, elem(account, 0))
      end)

    send_resp(conn, 200, Poison.encode!(content))
  end

  get "/api/delete/account" do
    case conn.params do
      %{"id" => id} ->
        case KBank.Account.delete_account(KBank.Account, id) do
          {_, nil, _} ->
            send_resp(conn, 500, Poison.encode!(%{"msg" => "The deletion failed !"}))

          _ ->
            content =
              KBank.Account.get_all(KBank.Account)
              |> Enum.map(fn account ->
                Map.put(elem(account, 1), :accnt_nb, elem(account, 0))
              end)

            send_resp(conn, 200, Poison.encode!(content))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/post/account" do
    case conn.params do
      %{"id" => id, "name" => name, "amt" => amt} ->
        case KBank.Account.lookup(KBank.Account, id) do
          {:ok, _content} ->
            cond do
              name == "" and amt == "" ->
                send_resp(
                  conn,
                  500,
                  Poison.encode!(%{"msg" => "You didn't provid any amount or name !"})
                )

              name == "" and Integer.parse(amt) == :error ->
                send_resp(conn, 500, Poison.encode!(%{"msg" => "Bad amount !"}))

              Integer.parse(amt) != :error ->
                if name != "" do
                  KBank.Account.update_name(KBank.Account, id, name)
                end

                if elem(Integer.parse(amt), 0) < 0 do
                  KBank.Account.retrieve_money(KBank.Account, id, -elem(Integer.parse(amt), 0))

                  new_content =
                    KBank.Account.get_all(KBank.Account)
                    |> Enum.map(fn account ->
                      Map.put(elem(account, 1), :accnt_nb, elem(account, 0))
                    end)

                  send_resp(conn, 200, Poison.encode!(new_content))
                else
                  KBank.Account.add_money(KBank.Account, id, elem(Integer.parse(amt), 0))

                  new_content =
                    KBank.Account.get_all(KBank.Account)
                    |> Enum.map(fn account ->
                      Map.put(elem(account, 1), :accnt_nb, elem(account, 0))
                    end)

                  send_resp(conn, 200, Poison.encode!(new_content))
                end

              name != "" ->
                KBank.Account.update_name(KBank.Account, id, name)

                new_content =
                  KBank.Account.get_all(KBank.Account)
                  |> Enum.map(fn account ->
                    Map.put(elem(account, 1), :accnt_nb, elem(account, 0))
                  end)

                send_resp(conn, 200, Poison.encode!(new_content))
            end

          :error ->
            send_resp(conn, 404, Poison.encode!(%{"msg" => "This id doesn't exist !"}))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get _ do
    send_file(conn, 200, "priv/static/accounts.html")
  end

  match _ do
    send_resp(conn, 404, "Page Not Found")
  end
end
