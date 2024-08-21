defmodule PomodoroPhxWeb.Admin.PomodoroLogController do
  use PomodoroPhxWeb, :controller

  alias Pomodoro.Schemas.PomodoroLog

  plug(:put_root_layout, {PomodoroPhxWeb.Layouts, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case PomodoroPhx.paginate_pomodoro_logs(params) do
      {:ok, assigns} ->
        render(conn, :index, assigns)
      {:error, error} ->
        conn
        |> put_flash(:error, "There was an error rendering Pomodoro logs. #{inspect(error)}")
        |> redirect(to: ~p"/admin/pomodoro_logs")
    end
  end

  def new(conn, _params) do
    changeset = Pomodoro.change_pomodoro_log(%PomodoroLog{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"pomodoro_log" => pomodoro_log_params}) do
    case Pomodoro.create_pomodoro_log(pomodoro_log_params) do
      {:ok, pomodoro_log} ->
        conn
        |> put_flash(:info, "Pomodoro log created successfully.")
        |> redirect(to: ~p"/admin/pomodoro_logs/#{pomodoro_log}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    pomodoro_log = Pomodoro.get_pomodoro_log!(id)
    render(conn, :show, pomodoro_log: pomodoro_log)
  end

  def edit(conn, %{"id" => id}) do
    pomodoro_log = Pomodoro.get_pomodoro_log!(id)
    changeset = Pomodoro.change_pomodoro_log(pomodoro_log)
    render(conn, :edit, pomodoro_log: pomodoro_log, changeset: changeset)
  end

  def update(conn, %{"id" => id, "pomodoro_log" => pomodoro_log_params}) do
    pomodoro_log = Pomodoro.get_pomodoro_log!(id)

    case Pomodoro.update_pomodoro_log(pomodoro_log, pomodoro_log_params) do
      {:ok, pomodoro_log} ->
        conn
        |> put_flash(:info, "Pomodoro log updated successfully.")
        |> redirect(to: ~p"/admin/pomodoro_logs/#{pomodoro_log}")
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, pomodoro_log: pomodoro_log, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    pomodoro_log = Pomodoro.get_pomodoro_log!(id)
    {:ok, _pomodoro_log} = Pomodoro.delete_pomodoro_log(pomodoro_log)

    conn
    |> put_flash(:info, "Pomodoro log deleted successfully.")
    |> redirect(to: ~p"/admin/pomodoro_logs")
  end
end
