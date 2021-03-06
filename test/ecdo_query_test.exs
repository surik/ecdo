defmodule Ecdo.Integration.QueryTest do
  use Ecto.Integration.Case

  import Ecto.Query
  import Ecdo

  alias Ecto.Integration.Post
  alias Ecto.Integration.Tag
  alias Ecto.Integration.Permalink
  alias Ecto.Integration.Custom
  alias Ecto.Integration.TestRepo
  alias Ecto.Integration.PoolRepo

  test "joins" do
    p1 = TestRepo.insert!(%Post{title: "1"})
    p2 = TestRepo.insert!(%Post{title: "2"})
    c1 = TestRepo.insert!(%Permalink{url: "1", post_id: p2.id})

    query = TestRepo.all query([{"p", Post}], %{join: ["permalink"], order_by: "p.id", select: "p.title,permalink.url", select_as: :list} )
    assert [["2", "1"]] = TestRepo.all(query)

    query = TestRepo.all query([{"p", Post}], %{left_join: ["permalink"], order_by: "p.id", select: "p.title,permalink.url", select_as: :list} )
    assert [["1", nil], ["2", "1"]] = TestRepo.all(query)
  end
end
