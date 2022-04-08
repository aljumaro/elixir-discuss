defmodule DiscussWeb.TopicController do
  use DiscussWeb, :controller
  import Ecto

  alias Discuss.Topic
  alias Discuss.Repo

  plug DiscussWeb.Plugs.RequireAuth when action in [:new, :create, :edit, :update, :delete]
  plug :check_topic_exists when action in [:edit, :update, :delete]
  plug :authorize_owner when action in [:edit, :update, :delete]

  def index(conn, _params) do
    topics = Repo.all(Topic)
    render(conn, "index.html", topics: topics)
  end

  def new(conn, _params) do
    changeset = Topic.changeset(%Topic{}, %{})

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"topic" => topic}) do
    changeset =
      conn.assigns.user
      |> build_assoc(:topics)
      |> Topic.changeset(topic)

    case Repo.insert(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic created")
        |> redirect(to: Routes.topic_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def edit(conn, %{"id" => topic_id}) do
    topic = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(topic)

    render(conn, "edit.html", changeset: changeset, topic: topic)
  end

  def show(conn, %{"id" => topic_id}) do
    # ! returns error if record is not found
    topic = Repo.get!(Topic, topic_id)

    render(conn, "show.html", topic: topic)
  end

  def update(conn, %{"id" => topic_id, "topic" => topic}) do
    topicDB = Repo.get(Topic, topic_id)
    changeset = Topic.changeset(topicDB, topic)

    case Repo.update(changeset) do
      {:ok, _topic} ->
        conn
        |> put_flash(:info, "Topic updated")
        |> redirect(to: Routes.topic_path(conn, :index))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, topic: topicDB)
    end
  end

  def delete(conn, %{"id" => topic_id}) do
    Repo.get!(Topic, topic_id) |> Repo.delete!()

    conn
    |> put_flash(:info, "Topic deleted")
    |> redirect(to: Routes.topic_path(conn, :index))
  end

  def authorize_owner(%{params: %{"id" => topic_id}} = conn, _params) do
    topic = Repo.get(Topic, topic_id)

    if !topic do
      conn
      |> put_flash(:error, "This topic does not exist")
      |> redirect(to: Routes.topic_path(conn, :index))
      |> halt()
    end

    if conn.assigns[:user].id == topic.user_id do
      conn
    else
      conn
      |> put_flash(:error, "You are not the owner of this topic")
      |> redirect(to: Routes.topic_path(conn, :index))
      |> halt()
    end
  end

  def check_topic_exists(%{params: %{"id" => topic_id}} = conn, _params) do
    topic = Repo.get(Topic, topic_id)

    if topic do
      conn
    else
      conn
      |> put_flash(:error, "This topic does not exist")
      |> redirect(to: Routes.topic_path(conn, :index))
      |> halt()
    end
  end
end
