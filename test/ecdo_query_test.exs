defmodule Ecdo.Integration.QueryTest do
  use Ecto.Integration.Case

  import Ecto.Query
  import Ecdo

  alias Ecto.Integration.Post
  alias Ecto.Integration.Tag
  alias Ecto.Integration.Permalink
  alias Ecto.Integration.Comment
  alias Ecto.Integration.Custom
  alias Ecto.Integration.TestRepo
  alias Ecto.Integration.PoolRepo

  test "joins" do
    p1 = TestRepo.insert!(%Post{title: "1"})
    p2 = TestRepo.insert!(%Post{title: "2"})
    c1 = TestRepo.insert!(%Permalink{url: "1", post_id: p2.id})
    c2 = TestRepo.insert!(%Comment{text: "a", post_id: p2.id})

    query = query([{"p", Post}], %{join: ["permalink"], order_by: "id", select: "p.title,permalink.url", select_as: :list} )
    assert [["2", "1"]] == TestRepo.all(query)

    # try to join unavailable talble
    query = query([{"p", Post}], %{join: ["permalink", "abc123"], order_by: "p.id", select: "p.title,permalink.url", select_as: :list} )
    assert [["2", "1"]] == TestRepo.all(query)

    query = query([{"p", Post}], %{left_join: ["permalink"], order_by: "p.id", select: "p.title,permalink.url", select_as: :list} )
    assert [["1", nil], ["2", "1"]] == TestRepo.all(query)

    # sort by joined table
    c3 = TestRepo.insert!(%Permalink{url: "2", post_id: p2.id})
    query = query([{"p", Post}], %{left_join: ["permalink"], order_by: "permalink.url", select: "p.title,permalink.url", select_as: :list} )
    assert [["1", nil], ["2", "1"], ["2", "2"]] == TestRepo.all(query)

    # multiple join
    query = query([{"p", Post}], %{join: ["permalink", "comments"], select: "p.title,permalink.url,comments.text", select_as: :list} )
    assert [["2", "1", "a"], ["2", "2", "a"]] == TestRepo.all(query)

    # multiple orderby
    query = query([{"p", Post}], %{join: ["permalink"], order_by: "id,permalink.url:desc", select: "p.title,permalink.url", select_as: :list} )
    assert [["2", "2"], ["2", "1"]] == TestRepo.all(query)

  end

  test "funs" do
    for i <- 1..3 do 
      p = TestRepo.insert!(%Post{title: "test", visits: i})
      TestRepo.insert!(%Permalink{url: "test_url", post_id: p.id})
    end

    query = query([{"p", Post}], %{where: "title == \"test\"", count: "id", select_as: :one} )
    assert TestRepo.one(from(p in Post, where: p.title == "test", select: count(p.id))) == TestRepo.one(query)

    # with join
    query = query([{"p", Post}], %{join: ["permalink"], where: "title == \"test\"", count: "permalink.url", select_as: :one} )
    assert TestRepo.one(from(p in Post, join: permalink in assoc(p, :permalink), 
                                        where: p.title == "test", 
                                        select: count(permalink.url))) == TestRepo.one(query)

    query = query([{"p", Post}], %{where: "title == \"test\"", max: "visits", select_as: :one} )
    assert TestRepo.one(from(p in Post, where: p.title == "test", select: max(p.visits))) == TestRepo.one(query)

    query = query([{"p", Post}], %{where: "title == \"test\"", min: "visits", select_as: :one} )
    assert TestRepo.one(from(p in Post, where: p.title == "test", select: min(p.visits))) == TestRepo.one(query)

    query = query([{"p", Post}], %{where: "title == \"test\"", avg: "visits", select_as: :one} )
    assert TestRepo.one(from(p in Post, where: p.title == "test", select: avg(p.visits))) == TestRepo.one(query)
  end

  test "limit, offset and distinct" do
    for i <- 1..4, do: TestRepo.insert!(%Post{title: "test_expr", visits: i})

    query = query([{"p", Post}], %{select: "id,title", limit: "2", where: "title == \"test_expr\"", select_as: :list})
    assert TestRepo.all(from(p in Post, select: [p.id, p.title], limit: 2, where: p.title == "test_expr")) == TestRepo.all(query)

    query = query([{"p", Post}], %{select: "id,title", limit: "2", offset: 2, where: "title == \"test_expr\"", select_as: :list})
    assert TestRepo.all(from(p in Post, select: [p.id, p.title], limit: 2, offset: 2, where: p.title == "test_expr")) == TestRepo.all(query)

    query = query([{"p", Post}], %{select: "id,title", limit: 2, offset: 4, where: "title == \"test_expr\"", select_as: :list})
    assert TestRepo.all(from(p in Post, select: [p.id, p.title], limit: 2, offset: 4, where: p.title == "test_expr")) == TestRepo.all(query)

    query = query([{"p", Post}], %{select: "id", distinct: true, where: "title == \"test_expr\"", select_as: :one})
    assert TestRepo.all(from(p in Post, select: p.id, distinct: true, where: p.title == "test_expr")) == TestRepo.all(query)
  end

  test "load" do
    p = TestRepo.insert!(%Post{title: "test_load"})
    TestRepo.insert!(%Permalink{url: "test_load_url", post_id: p.id})
    TestRepo.insert!(%Comment{text: "test_load_commnet", post_id: p.id})

    query = query([{"p", Post}], %{where: "title == \"test_load\"", load: ["permalink"]})
    post = TestRepo.one(query)
    assert post.title == "test_load"
    assert post.permalink.url == "test_load_url"

    query = query([{"p", Post}], %{where: "title == \"test_load\"", load: ["permalink", :comments]})
    post = TestRepo.one(query)
    assert post.title == "test_load"
    assert post.permalink.url == "test_load_url"
    assert hd(post.comments).text == "test_load_commnet"
  end
end
