defmodule Server.Router do
  use Ewebmachine.Builder.Resources
  if Mix.env() == :dev, do: plug(Ewebmachine.Plug.Debug)

  plug(Plug.Static, from: "priv/static", at: "/static")
  plug(Plug.Static, from: "priv/static", at: "/order/static")

  import Plug.Conn
  plug(:fetch_query_params)
  plug(:resource_match)
  plug(Ewebmachine.Plug.Run)
  plug(Ewebmachine.Plug.Send)
  resources_plugs(error_forwarding: "/error/:status", nomatch_404: true)

  resource "/api/pay/order" do
    %{}
  after
    allowed_methods(do: ["POST"])

    defh resource_exists(conn, state) do
      body = conn |> Ewebmachine.fetch_req_body([]) |> Ewebmachine.req_body() |> Poison.decode!()

      case is_binary(body) do
        true ->
          case Server.Riak.get_object("orders", body) do
            'not found\n' -> {false, conn, state}
            _ -> {true, conn, Map.put(state, :id, body)}
          end

        false ->
          {false, conn, state}
      end
    end

    defh process_post(conn, state) do
      response = Pay.process_payment(state.id)
      Pay.stop(state.id)

      case response do
        :action_unavailable ->
          {false, %{conn | resp_body: Poison.encode!(%{"msg" => response})}, state}

        _ ->
          # Because Riak is too slow in my computer
          Server.Riak.search("order_index", "*:*")
          # Because Riak is too slow in my computer
          :timer.sleep(1000)
          %{"response" => %{"docs" => records}} = Server.Riak.search("order_index", "*:*")

          {true, %{conn | resp_body: Poison.encode!(records)}, state}
      end
    end
  end

  resource "/api/delete/order/:id" do
    %{id: id}
  after
    allowed_methods(do: ["DELETE"])

    defh resource_exists(conn, state) do
      case Server.Riak.get_object("orders", state.id) do
        'not found\n' -> {false, conn, state}
        _ -> {true, conn, state}
      end
    end

    defh delete_resource(conn, state) do
      response = Server.Riak.delete_object("orders", state.id)

      case response do
        [] ->
          # Because Riak is too slow in my computer
          Server.Riak.search("order_index", "*:*")
          # Because Riak is too slow in my computer
          :timer.sleep(1000)
          %{"response" => %{"docs" => records}} = Server.Riak.search("order_index", "*:*")
          {true, %{conn | resp_body: Poison.encode!(records)}, state}

        _ ->
          {false, %{conn | resp_body: Poison.encode!(%{"msg" => response})}, state}
      end
    end
  end

  resource "/api/order" do
    %{}
  after
    allowed_methods(do: ["GET"])

    defh resource_exists(conn, state) do
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
              {true, conn, Map.put(state, :json_objs, docs)}

            _status_code ->
              {false, conn, Map.put(state, :json_objs, content["error"])}
          end

        _ ->
          {false, conn, Map.put(state, :json_objs, %{"msg" => "Error"})}
      end
    end

    content_types_provided(do: ["application/json": :to_json])
    defh(to_json, do: Poison.encode!(state[:json_objs]))
  end

  resource "/api/orders" do
    %{}
  after
    def insert_orders() do
      :inets.start()
      JsonLoader.load_to_riak_v2("../orders_dump/orders_chunk0.json")
    end

    allowed_methods(do: ["GET"])

    defh resource_exists(conn, state) do
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
              {true, conn, Map.put(state, :json_objs, docs)}

            _status_code ->
              {false, conn, Map.put(state, :json_objs, content["error"])}
          end

        _ ->
          {false, conn, Map.put(state, :json_objs, %{"msg" => "Error"})}
      end
    end

    content_types_provided(do: ["application/json": :to_json])
    defh(to_json, do: Poison.encode!(state[:json_objs]))
  end

  resource "/*path" do
    %{}
  after
    content_types_provided(do: ["text/html": :to_html])
    defh(to_html, do: File.read!("priv/static/index.html"))
  end
end
