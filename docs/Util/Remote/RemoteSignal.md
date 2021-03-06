# RemoteSignal

The [RemoteSignal](https://github.com/angrybino/Comet/blob/master/src/Util/Remote/RemoteSignal.lua) module is a class which binds a remote event to a custom signal object. A `RemoteSignal` object can only be created on the server and can only be exposed to the client. To communicate between the same containers e.g (server-server or client-client), use [Signal]() instead.

## Static methods

### new()
```lua
RemoteSignal.new() --> RemoteSignal []
```
	
Creates and returns a `RemoteSignal` object which is binded to a remote event.

### IsRemoteSignal()

```lua
RemoteSignal.IsRemoteSignal(self : any) --> boolean [IsRemoteSignal]
```
	
Returns a boolean indicating if `self` is a `RemoteSignal` object.

## Instance methods

### Connect()

```lua
RemoteSignal:Connect(callback : function) --> RBXScriptConnection []
```
	
Exactly like `RemoteSignal._remoteEvent.OnServerEvent:Connect(callback)`.

### FireClient()

```lua
RemoteSignal:FireClient(client : Player, ... : any) --> void []
```
	
Exactly like `RemoteSignal._remoteEvent:FireClient(client, ...)`.

### FireClients()

```lua
RemoteSignal:FireClient(clients : table, ...) --> void []
```
	
Exactly like 
	
```lua
for _, client in ipairs(clients) do
	remoteEvent:FireClient(client, ...)
end
```

### FireAllClients()

```lua
RemoteSignal:FireAllClients(...)
```

Exactly like `RemoteSignal._remoteEvent:FireAllClients(...)`

### Destroy()

```lua
RemoteSignal:Destroy()
```

Exactly like `RemoteSignal._remoteEvent:Destroy()`.