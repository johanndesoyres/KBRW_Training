defmodule Server.Router do
  use Plug.Router

  # plug(Plug.Static, from: "priv/static", at: "/static")
  # plug(Plug.Static, from: "priv/static", at: "/order/static")
  plug(Plug.Static, at: "/public", from: :tuto_kbrw_stack)
  import Plug.Conn
  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  require EEx
  EEx.function_from_file(:defp, :layout, "web/layout.html.eex", [:render])

  def insert_orders() do
    :inets.start()
    JsonLoader.load_to_riak_v2("../orders_dump/orders_chunk0.json")
  end

  delete "/api/delete/order" do
    case conn.params do
      %{"id" => id} ->
        response = Server.Riak.delete_object("orders", id)

        case response do
          [] ->
            [{_, %{"docs" => records}}, _ | _tail] = Server.Riak.search("order_index", "*:*")

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
        %{"query" => query, "page" => page, "rows" => rows, "sort" => sort} = conn.params
        {page, _rest} = Integer.parse(page, 0)
        {rows, _rest} = Integer.parse(rows, 0)
        content = Server.Riak.search("order_index", query, page, rows, sort)
        [{_, %{"docs" => docs}}, {_, %{"status" => status}} | _tail] = content

        case status do
          0 ->
            send_resp(conn, 200, Poison.encode!(docs))

          status ->
            send_resp(conn, status, Poison.encode!(content["error"]))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  get "/api/orders" do
    [{_, %{"docs" => records}}, _ | _tail] = Server.Riak.search("order_index", "*:*")

    if length(records) == 0 do
      insert_orders()
    end

    case conn.params do
      %{} ->
        %{"query" => query, "page" => page, "rows" => rows, "sort" => sort} = conn.params
        {page, _rest} = Integer.parse(page, 0)
        {rows, _rest} = Integer.parse(rows, 0)
        content = Server.Riak.search("order_index", query, page, rows, sort)

        [{_, %{"docs" => docs}}, {_, %{"status" => status}} | _tail] = content

        case status do
          0 ->
            send_resp(conn, 200, Poison.encode!(docs))

          status ->
            send_resp(conn, status, Poison.encode!(content["error"]))
        end

      _ ->
        send_resp(conn, 500, Poison.encode!(%{"msg" => "Error"}))
    end
  end

  # get _ do
  # send_file(conn, 200, "priv/static/index.html")
  # end

  get _ do
    conn = fetch_query_params(conn)

    render =
      Reaxt.render!(
        :app,
        %{path: conn.request_path, cookies: conn.cookies, query: conn.params},
        30_000
      )

    send_resp(
      put_resp_header(conn, "content-type", "text/html;charset=utf-8"),
      render.param || 200,
      layout(render)
    )
  end

  match _ do
    send_resp(conn, 404, "Page Not Found")
  end
end
