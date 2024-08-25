defmodule PomodoroPhxWeb.StatsControllerTest do
  use PomodoroPhxWeb.ConnCase, async: true
  use Machete
  alias NimbleCSV.RFC4180, as: CSV

  defmodule SimpleCsv do
    def parse(csv) do
      {:ok, stream} = StringIO.open(csv)

      stream
      |> IO.binstream(:line)
      |> CSV.parse_stream(skip_headers: false)
      |> Stream.transform(nil, fn
        headers, nil -> {[], headers}
        row, headers -> {[Enum.zip(headers, row) |> Map.new()], headers}
      end)
      |> Enum.to_list()
    end
  end

  test "extends the last pomodoro if it is not finished", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -30)

    pomodoro_log_fixture(%{"started_at" => started_at})

    assert text = text_response(get(conn, ~p"/api/stats.csv"), 200)

    assert SimpleCsv.parse(text)
           ~> [
             %{
               "finished_at" => iso8601_datetime(roughly: :now, offset_required: false),
               "rest_finished_at" => "",
               "rest_started_at" => "",
               "started_at" => iso8601_datetime(roughly: started_at, offset_required: false),
               "total_seconds" => ""
             }
           ]
  end

  test "extends the last limbo pomodoro", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -30)
    finished_at = NaiveDateTime.shift(now, minute: -5)

    pomodoro_log_fixture(%{"started_at" => started_at, "finished_at" => finished_at})

    assert text = text_response(get(conn, ~p"/api/stats.csv"), 200)

    assert SimpleCsv.parse(text)
           ~> [
             %{
               "finished_at" => iso8601_datetime(roughly: finished_at, offset_required: false),
               "rest_finished_at" => "",
               "rest_started_at" => iso8601_datetime(roughly: :now, offset_required: false),
               "started_at" => iso8601_datetime(roughly: started_at, offset_required: false),
               "total_seconds" => ""
             }
           ]
  end

  test "extends the last resting pomodoro", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -90)
    finished_at = NaiveDateTime.shift(now, minute: -45)
    rest_started_at = NaiveDateTime.shift(now, minute: -10)

    pomodoro_log_fixture(%{
      "started_at" => started_at,
      "finished_at" => finished_at,
      "rest_started_at" => rest_started_at
    })

    assert text = text_response(get(conn, ~p"/api/stats.csv"), 200)

    assert SimpleCsv.parse(text)
           ~> [
             %{
               "finished_at" => iso8601_datetime(roughly: finished_at, offset_required: false),
               "rest_finished_at" => iso8601_datetime(roughly: :now, offset_required: false),
               "rest_started_at" =>
                 iso8601_datetime(roughly: rest_started_at, offset_required: false),
               "started_at" => iso8601_datetime(roughly: started_at, offset_required: false),
               "total_seconds" => ""
             }
           ]
  end

  test "extends the last resting pomodoro a max of 15 minutes", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -90)
    finished_at = NaiveDateTime.shift(now, minute: -45)
    rest_started_at = NaiveDateTime.shift(now, minute: -30)
    max_rest_finished_at = NaiveDateTime.shift(now, minute: -15)

    pomodoro_log_fixture(%{
      "started_at" => started_at,
      "finished_at" => finished_at,
      "rest_started_at" => rest_started_at
    })

    assert text = text_response(get(conn, ~p"/api/stats.csv"), 200)

    assert SimpleCsv.parse(text)
           ~> [
             %{
               "finished_at" => iso8601_datetime(roughly: finished_at, offset_required: false),
               "rest_finished_at" =>
                 iso8601_datetime(roughly: max_rest_finished_at, offset_required: false),
               "rest_started_at" =>
                 iso8601_datetime(roughly: rest_started_at, offset_required: false),
               "started_at" => iso8601_datetime(roughly: started_at, offset_required: false),
               "total_seconds" => ""
             }
           ]
  end

  test "can render a completely finished pomodoro", %{conn: conn} do
    now = NaiveDateTime.utc_now()
    started_at = NaiveDateTime.shift(now, minute: -90)
    finished_at = NaiveDateTime.shift(now, minute: -45)
    rest_started_at = NaiveDateTime.shift(now, minute: -30)
    rest_finished_at = NaiveDateTime.shift(now, minute: -15)

    pomodoro_log_fixture(%{
      "started_at" => started_at,
      "finished_at" => finished_at,
      "rest_started_at" => rest_started_at,
      "rest_finished_at" => rest_finished_at
    })

    assert text = text_response(get(conn, ~p"/api/stats.csv"), 200)

    assert SimpleCsv.parse(text)
           ~> [
             %{
               "finished_at" => iso8601_datetime(roughly: finished_at, offset_required: false),
               "rest_finished_at" =>
                 iso8601_datetime(roughly: rest_finished_at, offset_required: false),
               "rest_started_at" =>
                 iso8601_datetime(roughly: rest_started_at, offset_required: false),
               "started_at" => iso8601_datetime(roughly: started_at, offset_required: false),
               "total_seconds" => ""
             }
           ]
  end

  @valid_pomodoro_log_attrs %{"started_at" => ~N[2020-01-01 00:00:00]}

  def pomodoro_log_fixture(attrs \\ %{}) do
    attrs = Map.merge(@valid_pomodoro_log_attrs, attrs)
    {:ok, log} = Pomodoro.create_pomodoro_log(attrs)
    log
  end
end
