defmodule ApiGateway.GRPCClient do
  use GenServer

  alias GRPC.Stub

  @grpc_server System.get_env("AUTH_SERVICE")
  # Retry every 5 seconds
  @retry_interval 5000

  # Public API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def call_service(method, request) do
    GenServer.call(__MODULE__, {:call_service, method, request})
  end

  # GenServer Callbacks
  @impl true
  def init(_) do
    # Try to connect initially
    case Stub.connect(@grpc_server,
           adapter_opts: %{
             keepalive: %{
               # Frequency of PING frames in milliseconds
               # 20 seconds
               interval: 20000,
               # Timeout for awaiting PING responses
               # 5 seconds
               timeout: 5000
             }
           }
         ) do
      {:ok, channel} ->
        {:ok, %{channel: channel}}

      {:error, _reason} ->
        # Schedule a reconnect if the initial connection fails
        Process.send_after(self(), :reconnect, @retry_interval)
        {:ok, %{channel: nil}}
    end
  end

  @impl true
  def handle_call({:call_service, method, request}, _from, %{channel: nil} = state) do
    # If the channel is nil, attempt to reconnect
    {:reply, {:error, :not_connected}, state}
  end

  def handle_call({:call_service, method, request}, _from, %{channel: channel} = state) do
    # Attempt the gRPC call using the channel
    response =
      case method do
        {module, function} ->
          apply(module, function, [channel, request])
      end

    # Handle connection failure and trigger reconnect
    case response do
      {:ok, _result} ->
        {:reply, response, state}

      {:error, _reason} ->
        Process.send_after(self(), :reconnect, @retry_interval)
        {:reply, {:error, :connection_failed}, %{state | channel: nil}}
    end
  end

  # Handle the reconnect message
  @impl true
  def handle_info(:reconnect, %{channel: nil} = state) do
    reconnect(state)
  end

  def handle_info(:reconnect, state) do
    # Ignore if already connected
    {:noreply, state}
  end

  # Private function to attempt reconnection
  defp reconnect(state) do
    case Stub.connect(@grpc_server,
           adapter_opts: %{
             keepalive: %{
               # Frequency of PING frames in milliseconds
               # 20 seconds
               interval: 20_000,
               # Timeout for awaiting PING responses
               # 5 seconds
               timeout: 5_000
             }
           }
         ) do
      {:ok, channel} ->
        {:noreply, %{state | channel: channel}}

      {:error, _reason} ->
        # Retry reconnection after a delay
        Process.send_after(self(), :reconnect, @retry_interval)
        {:noreply, state}
    end
  end
end
