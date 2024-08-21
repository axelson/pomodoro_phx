defmodule PomodoroPhxWeb.Admin.PomodoroLogControllerTest do
  use PomodoroPhxWeb.ConnCase

  alias PomodoroPhx.Pomodoro

  @create_attrs %{started_at: ~N[2024-08-20 12:24:00], finished_at: ~N[2024-08-20 12:24:00], rest_started_at: ~N[2024-08-20 12:24:00], rest_finished_at: ~N[2024-08-20 12:24:00], total_seconds: 42}
  @update_attrs %{started_at: ~N[2024-08-21 12:24:00], finished_at: ~N[2024-08-21 12:24:00], rest_started_at: ~N[2024-08-21 12:24:00], rest_finished_at: ~N[2024-08-21 12:24:00], total_seconds: 43}
  @invalid_attrs %{started_at: nil, finished_at: nil, rest_started_at: nil, rest_finished_at: nil, total_seconds: nil}

  def fixture(:pomodoro_log) do
    {:ok, pomodoro_log} = Pomodoro.create_pomodoro_log(@create_attrs)
    pomodoro_log
  end

  describe "index" do
    test "lists all pomodoro_logs", %{conn: conn} do
      conn = get conn, ~p"/admin/pomodoro_logs"
      assert html_response(conn, 200) =~ "Pomodoro logs"
    end
  end

  describe "new pomodoro_log" do
    test "renders form", %{conn: conn} do
      conn = get conn, ~p"/admin/pomodoro_logs/new"
      assert html_response(conn, 200) =~ "New Pomodoro log"
    end
  end

  describe "create pomodoro_log" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, ~p"/admin/pomodoro_logs", pomodoro_log: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == "/admin/pomodoro_logs/#{id}"

      conn = get conn, ~p"/admin/pomodoro_logs/#{id}"
      assert html_response(conn, 200) =~ "Pomodoro log Details"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, ~p"/admin/pomodoro_logs", pomodoro_log: @invalid_attrs
      assert html_response(conn, 200) =~ "New Pomodoro log"
    end
  end

  describe "edit pomodoro_log" do
    setup [:create_pomodoro_log]

    test "renders form for editing chosen pomodoro_log", %{conn: conn, pomodoro_log: pomodoro_log} do
      conn = get conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}/edit"
      assert html_response(conn, 200) =~ "Edit Pomodoro log"
    end
  end

  describe "update pomodoro_log" do
    setup [:create_pomodoro_log]

    test "redirects when data is valid", %{conn: conn, pomodoro_log: pomodoro_log} do
      conn = put conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}", pomodoro_log: @update_attrs
      assert redirected_to(conn) == ~p"/admin/pomodoro_logs/#{pomodoro_log}"

      conn = get conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}" 
      assert html_response(conn, 200)
    end

    test "renders errors when data is invalid", %{conn: conn, pomodoro_log: pomodoro_log} do
      conn = put conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}", pomodoro_log: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Pomodoro log"
    end
  end

  describe "delete pomodoro_log" do
    setup [:create_pomodoro_log]

    test "deletes chosen pomodoro_log", %{conn: conn, pomodoro_log: pomodoro_log} do
      conn = delete conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}"
      assert redirected_to(conn) == "/admin/pomodoro_logs"
      assert_error_sent 404, fn ->
        get conn, ~p"/admin/pomodoro_logs/#{pomodoro_log}"
      end
    end
  end

  defp create_pomodoro_log(_) do
    pomodoro_log = fixture(:pomodoro_log)
    {:ok, pomodoro_log: pomodoro_log}
  end
end
