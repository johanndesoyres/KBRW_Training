defmodule Server.Router do
  use Plug.Router

  plug(Plug.Static, from: "priv/static", at: "/static")
  plug(Plug.Static, from: "priv/static", at: "/order/static")

  import Plug.Conn

  plug(:fetch_query_params)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Poison)
  plug(:match)
  plug(:dispatch)

  def insert_orders() do
    :inets.start()
    JsonLoader.load_to_riak_v2("../orders_dump/orders_chunk0.json")
  end

  post "/api/pay/order" do
    case conn.body_params do
      %{"_json" => id} ->
        response = Pay.process_payment(id)
        Pay.stop(id)

        case response do
          :action_unavailable ->
            send_resp(conn, 500, Poison.encode!(%{"msg" => response}))

          _ ->
            # Because Riak is too slow in my computer
            Server.Riak.search("order_index", "*:*")
            # Because Riak is too slow in my computer
            :timer.sleep(1000)
            %{"response" => %{"docs" => records}} = Server.Riak.search("order_index", "*:*")

            send_resp(conn, 200, Poison.encode!(records))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  delete "/api/delete/order" do
    case conn.params do
      %{"id" => id} ->
        response = Server.Riak.delete_object("orders", id)

        case response do
          [] ->
            # Because Riak is too slow in my computer
            Server.Riak.search("order_index", "*:*")
            # Because Riak is too slow in my computer
            :timer.sleep(1000)
            %{"response" => %{"docs" => records}} = Server.Riak.search("order_index", "*:*")

            send_resp(conn, 200, Poison.encode!(records))

          _ ->
            send_resp(conn, 500, Poison.encode!(%{"msg" => response}))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/order" do
    case conn.params do
      %{} ->
        %{"query" => query, "page" => page, "rows" => rows, "sort" => sort} = conn.params
        {page, _rest} = Integer.parse(page)
        {rows, _rest} = Integer.parse(rows)
        content = Server.Riak.search("order_index", query, page, rows, sort)
        %{"responseHeader" => %{"status" => status}} = content

        case status do
          0 ->
            %{"response" => %{"docs" => docs}} = content
            send_resp(conn, 200, Poison.encode!(docs))

          status_code ->
            send_resp(conn, status_code, Poison.encode!(content["error"]))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/orders" do
    %{"response" => %{"docs" => records}} = Server.Riak.search("order_index", "*:*")

    if length(records) == 0 do
      insert_orders()
    end

    case conn.params do
      %{} ->
        %{"query" => query, "page" => page, "rows" => rows, "sort" => sort} = conn.params

        {page, _rest} = Integer.parse(page)
        {rows, _rest} = Integer.parse(rows)
        content = Server.Riak.search("order_index", query, page, rows, sort)

        %{"responseHeader" => %{"status" => status}} = content

        case status do
          0 ->
            %{"response" => %{"docs" => docs}} = content
            send_resp(conn, 200, Poison.encode!(docs))

          status_code ->
            send_resp(conn, status_code, Poison.encode!(content["error"]))
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
