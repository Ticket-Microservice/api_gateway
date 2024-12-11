defmodule ApiGatewayWeb.Controller.Authentication do
  def login(conn, params)do
    try do
      case Ticket_BE.Guardian.authenticate(
        params["email"],
        params["password"]
      ) do
        {:ok, token, _payload} ->
          conn
          |> put_status(:ok)
          |> json(%{data: %{
            token: token
          }, message: "success"})

          {:error, msg} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{data: [], errors: [msg]})
      end
    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end
end
