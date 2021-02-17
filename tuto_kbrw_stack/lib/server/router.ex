defmodule Server.Router do
  use Plug.Router

  plug(Plug.Static, from: "priv/static", at: "/static")
  import Plug.Conn

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  # get "/" do
  # send_resp(conn, 200, "Welcome")
  # end

  get "/get" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.lookup(Server.Database, id) do
          {:ok, content} -> send_resp(conn, 200, inspect(content))
          :error -> send_resp(conn, 404, "This id doesn't exist !")
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/create" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.create(Server.Database, id, conn.params) do
          {_, :error, _} -> send_resp(conn, 500, "The insertion failed")
          _ -> send_resp(conn, 200, "The insertion sucessed")
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/delete" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.delete(Server.Database, id) do
          {_, nil, _} -> send_resp(conn, 500, "The deletion failed")
          _ -> send_resp(conn, 200, "The deletion sucessed")
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/update" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.delete(Server.Database, id) do
          {_, nil, _} ->
            send_resp(conn, 500, "This id doesn't exist")

          _ ->
            map = Map.drop(conn.params, ["id"])

            Server.Database.create(Server.Database, id, map)
            send_resp(conn, 200, "The insertion sucessed")
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/search" do
    case conn.params do
      %{} ->
        content = Server.Database.search(Server.Database, conn.params)
        send_resp(conn, 200, inspect(content))

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/api/orders" do
    case conn.params do
      %{} ->
        case map_size(conn.params) do
          0 ->
            content =
              Server.Database.get_all(Server.Database)
              |> Enum.map(fn order ->
                Map.put(elem(order, 1), :id, elem(order, 0))
              end)

            send_resp(conn, 200, Poison.encode!(content))

          _ ->
            content = Server.Database.search(Server.Database, conn.params)
            send_resp(conn, 200, inspect(content))
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  get "/api/order" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.lookup(Server.Database, id) do
          {:ok, content} ->
            send_resp(conn, 200, Poison.encode!(content))

          :error ->
            send_resp(conn, 404, "This id doesn't exist !")
        end

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  # get(_, do: send_file(conn, 200, "priv/static/index.html"))

  get _ do
    orders = [
      {"000000189",
       %{full_name: "TOTO & CIE", billing_address: "Some where in the world", items: 2}},
      {"000000189",
       %{full_name: "TOTO & CIE", billing_address: "Some where in the world", items: 2}},
      {"000000190",
       %{full_name: "Looney Toons", billing_address: "The Warner Bros Company", items: 3}},
      {"000000191", %{full_name: "Asterix & Obelix", billing_address: "Armorique", items: 29}},
      {"000000192",
       %{
         full_name: "Lucky Luke",
         billing_address: "A Cowboy doesn't have an address. Sorry",
         items: 0
       }}
    ]

    orders
    |> Enum.map(fn {id, val} ->
      case Server.Database.lookup(Server.Database, id) do
        :error ->
          Server.Database.create(Server.Database, id, val)

        _ ->
          true
      end
    end)

    send_file(conn, 200, "priv/static/index.html")
  end

  match _ do
    send_resp(conn, 404, "Page Not Found")
  end
end
