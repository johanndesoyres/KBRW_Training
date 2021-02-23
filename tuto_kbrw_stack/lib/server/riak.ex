defmodule Server.Riak do
  def get_buckets do
    case :httpc.request(:get, {'http://127.0.0.1:8098/buckets?buckets=true', []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} -> Poison.decode!(body)["buckets"]
      _ -> Poison.encode!(%{"msg" => "Can't get the list of buckets !"})
    end
  end

  def get_keys(bucket) do
    case :httpc.request(
           :get,
           {'http://127.0.0.1:8098/buckets/#{bucket}/keys?keys=true', []},
           [],
           []
         ) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} -> Poison.decode!(body)["keys"]
      _ -> Poison.encode!(%{"msg" => "Can't get the list of keys !"})
    end
  end

  def get_object(bucket, key) do
    case :httpc.request(:get, {'http://127.0.0.1:8098/buckets/#{bucket}/keys/#{key}', []}, [], []) do
      {:ok, {_status, _headers, body}} -> Poison.decode!(body)
      _ -> Poison.encode!(%{"msg" => "Can't get the object with the given key!"})
    end
  end

  def post_object(bucket, key, body) do
    case :httpc.request(
           :post,
           {'http://127.0.0.1:8098/buckets/#{bucket}/keys/#{key}?returnbody=true', [],
            'application/json', body},
           [],
           []
         ) do
      {:ok, {_status, _headers, body}} ->
        Poison.decode!(body)

      _ ->
        Poison.encode!(%{
          "msg" => "Can't create the object with the given key, hearders and body !"
        })
    end
  end

  def delete_object(bucket, key) do
    case :httpc.request(
           :delete,
           {'http://127.0.0.1:8098/buckets/#{bucket}/keys/#{key}returnbody=true', []},
           [],
           []
         ) do
      {:ok, {{'HTTP/1.1', 204, _msg}, _headers, body}} -> body
      {:ok, {{'HTTP/1.1', 404, _msg}, _headers, body}} -> body
      _ -> Poison.encode!(%{"msg" => "Can't delete the object with the given key!"})
    end
  end

  def upload_schema(path, schema) do
    case File.read!(path) do
      {:error, _} ->
        Poison.encode!(%{"msg" => "Wrong path !"})

      content ->
        :httpc.request(
          :put,
          {'http://127.0.0.1:8098/search/schema/#{schema}', [], 'application/xml', content},
          [],
          []
        )
    end
  end

  def put_index(schema, index) do
    :httpc.request(
      :put,
      {'http://127.0.0.1:8098/search/index/#{index}', [], 'application/json',
       '{"schema": "#{schema}"}'},
      [],
      []
    )
  end

  def assign_index(bucket, index) do
    :httpc.request(
      :put,
      {'http://localhost:8098/buckets/#{bucket}/props', [], 'application/json',
       '{"props":{"search_index":"#{index}"}}'},
      [],
      []
    )
  end

  def delete_bucket(bucket) do
    keys = Server.Riak.get_keys(bucket)

    cond do
      keys == [] ->
        keys

      is_list(keys) ->
        keys
        |> Enum.map(fn key ->
          Server.Riak.delete_object(bucket, key)
        end)

      true ->
        Poison.encode!(%{"msg" => "Can't delete the bucket !"})
    end
  end

  def update_bucket(bucket, field, subfield, data) do
    Server.Riak.get_keys(bucket)
    |> Enum.map(fn key ->
      content = Server.Riak.get_object(bucket, key)
      # new_content = %{content | field => data}
      newSubfield = %{content[field] | subfield => data}
      new_content = %{content | field => newSubfield}
      Server.Riak.post_object(bucket, key, Poison.encode!(new_content))
    end)
  end

  def search(index, query, page \\ 0, rows \\ 30, sort \\ "creation_date_index") do
    case :httpc.request(
           :get,
           {'http://127.0.0.1:8098/search/query/#{index}/?wt=json&q=#{query}&rows=#{rows}&start=#{
              page * rows
            }&sort=#{sort}', []},
           [],
           []
         ) do
      {:ok, {_status, _headers, body}} -> Poison.decode!(body)
      _ -> Poison.encode!(%{"msg" => "Can't perform the query !"})
    end
  end

  def search2(index, query, page \\ 0, rows \\ 30, sort \\ "creation_date_index") do
    IO.inspect(
      'http://127.0.0.1:8098/search/query/#{index}/?wt=json&q=#{query}&rows=#{rows}&start=#{
        page * rows
      }&sort=#{sort}'
    )

    :httpc.request(
      :get,
      {'http://127.0.0.1:8098/search/query/#{index}/?wt=json&q=#{query}&rows=#{rows}&start=#{
         page * rows
       }&sort=#{sort}', []},
      [],
      []
    )
  end
end
