defmodule ApiGatewayWeb.Controller.Authentication do
  use ApiGatewayWeb, :controller

  alias TicketAuthentications.LoginRequest
  alias TicketAuthentications.Register.Stub, as: RegisterStub

  def login(conn, params)do
    try do
      request = %LoginRequest{
        email: params["email"],
        pwd: params["pwd"]
      }

      case GRPCClient.call_service({RegisterStub, :Login}, request) do
        {:ok, response} -> {:ok, response.result}
        {:error, error} -> {:error, error}
      end
      # case Ticket_BE.Guardian.authenticate(
      #   params["email"],
      #   params["password"]
      # ) do
      #   {:ok, token, _payload} ->
      #     conn
      #     |> put_status(:ok)
      #     |> json(%{data: %{
      #       token: token
      #     }, message: "success"})

      #     {:error, msg} ->
      #     conn
      #     |> put_status(:internal_server_error)
      #     |> json(%{data: [], errors: [msg]})
      # end
    rescue
      e ->
        Logger.error(e)

        conn
        |> put_status(:internal_server_error)
        |> json(%{message: e.message})
    end
  end
end
