defmodule Server.Router do
  use Plug.Router
  import Plug.Conn

  plug(:fetch_query_params)
  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "Welcome")
  end

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

  match _ do
    send_resp(conn, 404, "Page Not Found")
  end
end
