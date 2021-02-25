defmodule Server.Router do
  use Plug.Router

  plug(Plug.Static, from: "priv/static", at: "/static")
  plug(Plug.Static, from: "priv/static", at: "/order/static")

  import Plug.Conn

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  def insert_orders() do
    :inets.start()
    JsonLoader.load_to_riak_v3("../orders_dump/orders_chunk0.json")
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
