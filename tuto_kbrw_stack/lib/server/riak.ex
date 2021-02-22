defmodule Server.Riak do
  def get_buckets do
    case :httpc.request(:get, {'http://127.0.0.1:55046/buckets?buckets=true', []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} -> Poison.decode!(body)["buckets"]
      _ -> Poison.encode!(%{"msg" => "Can't get the list of buckets !"})
  end

  def get_keys(bucket) do
    case :httpc.request(:get, {'http://127.0.0.1:55046/buckets/#{bucket}/keys?keys=true', []}, [], []) do
      {:ok, {{'HTTP/1.1', 200, 'OK'}, _headers, body}} -> Poison.decode!(body)["keys"]
      _ -> Poison.encode!(%{"msg" => "Can't get the list of keys !"})
  end

  def get_object(bucket, key) do
    case :httpc.request(:get, {'http://127.0.0.1:55046/buckets/#{bucket}/keys/#{key}', []}, [], []) do
      {:ok, {_status, _headers, body}} -> Poison.decode!(body)
      _ -> Poison.encode!(%{"msg" => "Can't get the object with the given key!"})
  end


  def put_object(bucket, key, body) do
    case :httpc.request(:put, {'http://127.0.0.1:55046/buckets/#{bucket}/keys/#{key}?returnbody=true',
                              [],
                              "application/json",
                              body}, [], []) do
      {:ok, {_status, _headers, body}} -> Poison.decode!(body)
      _ -> Poison.encode!(%{"msg" => "Can't create the object with the given key, hearders and body !"})
  end

  def delete_object(bucket, key) do
    case :httpc.request(:delete, {'http://127.0.0.1:55046/buckets/#{bucket}/keys/#{key}', []}, [], []) do
      {:ok, {{'HTTP/1.1', 204, 'NO CONTENT'}, _headers, body}} -> Poison.decode!(body)
      {:ok, {{'HTTP/1.1', 404, 'NOT FOUND'}, _headers, body}} -> Poison.decode!(body)
      _ -> Poison.encode!(%{"msg" => "Can't delete the object with the given key!"})
  end
end
