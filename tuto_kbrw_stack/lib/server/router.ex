defmodule Server.Router do
  use Plug.Router

  plug(Plug.Static, from: "priv/static", at: "/static")
  plug(Plug.Static, from: "priv/static", at: "/order/static")

  import Plug.Conn

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/old/get" do
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

  get "/old//create" do
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

  get "/old//delete" do
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

  get "/old//update" do
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

  get "/old//search" do
    case conn.params do
      %{} ->
        content = Server.Database.search(Server.Database, conn.params)
        send_resp(conn, 200, inspect(content))

      _ ->
        send_resp(conn, 500, "Error")
    end
  end

  # ---------------------------------------------------------------------------

  def old_insert_orders do
    orders = [
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
  end

  get "/old/api/orders" do
    if Server.Database.is_empty(Server.Database) do
      insert_orders()
    end

    case conn.params do
      %{"del" => id} ->
        case Server.Database.delete(Server.Database, id) do
          {_, nil, _} ->
            send_resp(conn, 500, Poison.encode!(%{"msg" => "The deletion failed !"}))

          _ ->
            content =
              Server.Database.get_all(Server.Database)
              |> Enum.map(fn order ->
                Map.put(elem(order, 1), :id, elem(order, 0))
              end)

            send_resp(conn, 200, Poison.encode!(content))
        end

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
            content =
              Server.Database.search(Server.Database, conn.params)
              |> Enum.map(fn order ->
                Map.put(elem(order, 1), :id, elem(order, 0))
              end)

            send_resp(conn, 200, Poison.encode!(content))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/old/api/order" do
    case conn.params do
      %{"id" => id} ->
        case Server.Database.lookup(Server.Database, id) do
          {:ok, content} ->
            send_resp(conn, 200, Poison.encode!(Map.put(content, :id, id)))

          :error ->
            send_resp(conn, 404, Poison.encode!(%{"msg" => "This id doesn't exist !"}))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  # ---------------------------------------------------------------------------

  def insert_orders() do
    :inets.start()
    JsonLoader.load_to_riak_v3("../orders_dump/orders_chunk0.json")
  end

  def filter_order(order) do
    filtered_order = Map.put(%{}, "id", order["remoteid"])

    filtered_order =
      Map.put(
        filtered_order,
        "full_name",
        order["custom"]["customer"]["full_name"]
      )

    filtered_order =
      Map.put(
        filtered_order,
        "billing_address",
        order["custom"]["billing_address"]["street"] |> Enum.at(0)
      )

    filtered_order =
      Map.put(
        filtered_order,
        "items",
        length(order["custom"]["items"])
      )

    filtered_order
  end

  delete "/api/delete/order" do
    case conn.params do
      %{"id" => id} ->
        response = Server.Riak.delete_object("orders", id)

        case response do
          [] ->
            records =
              (Server.Riak.search(
                 "order_index",
                 "*:*"
               )
               |> Enum.at(0)
               |> elem(1))["docs"]

            send_resp(conn, 200, Poison.encode!(records))

          _ ->
            send_resp(conn, 500, response)
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/order" do
    case conn.params do
      %{} ->
        content =
          Server.Riak.search(
            "order_index",
            conn.params["query"],
            elem(Integer.parse(conn.params["page"]), 0),
            elem(Integer.parse(conn.params["rows"]), 0),
            conn.params["sort"]
          )

        case (content |> Enum.at(1) |> elem(1))["status"] do
          0 ->
            send_resp(conn, 200, Poison.encode!((content |> Enum.at(0) |> elem(1))["docs"]))

          status ->
            send_resp(conn, status, Poison.encode!(content["error"]))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/orders" do
    records =
      (Server.Riak.search(
         "order_index",
         "*:*"
       )
       |> Enum.at(0)
       |> elem(1))["docs"]

    if length(records) == 0 do
      insert_orders()
    end

    case conn.params do
      %{} ->
        content =
          Server.Riak.search(
            "order_index",
            conn.params["query"],
            elem(Integer.parse(conn.params["page"]), 0),
            elem(Integer.parse(conn.params["rows"]), 0),
            conn.params["sort"]
          )

        case (content |> Enum.at(1) |> elem(1))["status"] do
          0 ->
            send_resp(conn, 200, Poison.encode!((content |> Enum.at(0) |> elem(1))["docs"]))

          status ->
            send_resp(conn, status, Poison.encode!(content["error"]))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get _ do
    send_file(conn, 200, "priv/static/index.html")
  end

  match _ do
    send_resp(conn, 404, "Page Not Found")
  end
end
