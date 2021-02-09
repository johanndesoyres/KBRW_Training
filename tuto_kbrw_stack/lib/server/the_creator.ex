defmodule Server.TheCreator do
  @doc false
  defmacro __using__(_opts) do
    quote do
      import Server.TheCreator
      import Plug.Conn
      @before_compile Server.TheCreator
      @func_names []
      @error_code 404
      @error_content "Go away, you are not welcome here."
    end
  end

  @doc false
  defmacro __before_compile__(_opts) do
    quote do
      def init(opts) do
        opts
      end

      def call(conn, _opts) do
        @func_names
        |> Enum.each(fn func_name ->
          apply(__MODULE__, func_name, [conn])
        end)
      end
    end
  end

  defmacro my_error(code: code, content: content) do
    quote do
      @error_code unquote(code)
      @error_content unquote(content)
    end
  end

  defmacro my_get(request_path, do: {status, resp_body}) do
    function_name = String.to_atom("GET " <> request_path)

    quote do
      @func_names [unquote(function_name) | @func_names]
      def unquote(function_name)(conn) do
        if(conn.request_path == unquote(request_path)) do
          send_resp(conn, unquote(status), unquote(resp_body))
        else
          send_resp(conn, @error_code, @error_content)
        end
      end
    end
  end
end
