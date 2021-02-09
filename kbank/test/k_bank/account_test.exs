defmodule KBank.AccountTest do
  use ExUnit.Case, async: true
  doctest KBank

  setup context do
    _ = start_supervised!({KBank.Account, name: context.test})
    %{database: context.test}
  end

  test "create account", %{database: database} do
    assert KBank.Account.lookup(database, "1234567891234") == :error

    accnt_nb =
      KBank.Account.create_account(database, %{
        name: "de Soyres",
        first_name: "Johann",
        amt: 100
      })

    assert {:ok,
            %{
              amt: 100,
              first_name: "Johann",
              last_update: _,
              name: "de Soyres"
            }} = KBank.Account.lookup(database, accnt_nb)
  end

  test "delete account", %{database: database} do
    accnt_nb =
      KBank.Account.create_account(database, %{
        name: "de Soyres",
        first_name: "Johann",
        amt: 100
      })

    assert {:ok,
            %{
              amt: 100,
              first_name: "Johann",
              last_update: _,
              name: "de Soyres"
            }} = KBank.Account.lookup(database, accnt_nb)

    KBank.Account.delete_account(database, accnt_nb)

    assert :error = KBank.Account.lookup(database, accnt_nb)
  end

  test "Add money", %{database: database} do
    accnt_nb =
      KBank.Account.create_account(database, %{
        name: "de Soyres",
        first_name: "Johann",
        amt: 100
      })

    KBank.Account.add_money(database, accnt_nb, 200)

    assert {:ok,
            %{
              amt: 300,
              first_name: "Johann",
              last_update: _,
              name: "de Soyres"
            }} = KBank.Account.lookup(database, accnt_nb)
  end

  test "Retrieve money", %{database: database} do
    accnt_nb =
      KBank.Account.create_account(database, %{
        name: "de Soyres",
        first_name: "Johann",
        amt: 100
      })

    KBank.Account.retrieve_money(database, accnt_nb, 50)

    assert {:ok,
            %{
              amt: 50,
              first_name: "Johann",
              last_update: _,
              name: "de Soyres"
            }} = KBank.Account.lookup(database, accnt_nb)
  end

  test "Test database save", %{database: database} do
    accnt_nb =
      KBank.Account.create_account(database, %{
        name: "de Soyres",
        first_name: "Johann",
        amt: 100
      })

    send(database, :kill)

    assert {:ok,
            %{
              amt: 100,
              first_name: "Johann",
              last_update: _,
              name: "de Soyres"
            }} = KBank.Account.lookup(database, accnt_nb)
  end
end
