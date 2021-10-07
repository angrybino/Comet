# Services

Services are singletons that serve a specific purpose on the server. For e.g, you may have a `PlayerData` service, which manages player data in your game. Services serve as the backbones of your game, they can communicate with each other, communicate with the client, etc.

In this section, we'll gradually create a very basic service which manages player experience.

## Creating services

A service is simply a `ModuleScript` in it's simplest form:

```lua
local ExpService = {
    Client = {}
}

function ExpService.Init()

end

function ExpService.Start()

end

return ExpService
```

!!!note
    - The name of the service will be the name of the module script it is nested in.
    - The `Client` table is optional. However, it is good practice to keep it. The purpose of it will be discussed later in this section.

## `Init` and `Start` methods

These methods are optional. To learn more about them, see the [lifecycle guide](Lifecycle.md).

## Injected members

Members that are injected when a service is initialized (see the [lifecycle guide](Lifecycle.md)). 

| Injected Members      | Description                          |
| ----------- | ------------------------------------ |
| `Comet`       | The reference to the required Comet module  |

## Adding methods and members

A service at it's core is just a `ModuleScript`, so treat it as such. With this knowledge in mind, we can add a few methods to manage player exp:

```lua
function ExpService.SetPlayerExp(player, exp)

end

function ExpService.GetPlayerExp(player)

end
```

Now, let's create a new member `PlayerExpData`, to store player experiences:

```lua
ExpService.PlayerExpData = {}
```

Let's change the methods to use this member:

```lua
function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
end

function ExpService.GetPlayerExp(player)
    ExpService.PlayerExpData[player.Name] = ExpService.PlayerExpData[player.Name] or 0
    return ExpService.PlayerExpData[player.Name]
end
```

## Using signals

What if we wanted to know whenever a player's exp was set? Well, we need a signal which will be fired everytime the `SetPlayerExp` is called and listen to it.

Let's create a signal, we'll do it in the `Init` method:

```lua
function ExpService.Init()
    local Signal = require(ExpService.Comet.Util.Shared.Signal)

    ExpService.OnPlayerExpSet = Signal.new()
    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("%s's exp was set to %d"):format(playerName, exp))
    end)
end
```


Now let's change the `SetPlayerExp` method to fire off this signal whenever it is called:

```lua
function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
    ExpService.OnPlayerExpSet:Fire(player.Name, exp)
end
```

```lua
-- Some other service..


function SomeOtherService.Start()
    local ExpService = SomeOtherService.Comet.GetService("ExpService")
    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("Exp changed for %s to %d"):format(playerName, exp))
    end)
end
```

## Server-client communication

What if the client wants to know how much exp it has currently? This would require communication between the server and the client, and Comet efficiently abstracts this from the developer (this is also the main reason why Comet was made!).

### The `Client` table

Now, it's time to finally discuss the purpose of the `Client` table in a service. This is the table where you store anything you want to expose to the client, this is what the client will see when they access a service!

### Exposing and using methods

Let's create a client exposed method `GetExp` in `ExpService.Client` and have it return the exp of the client who called the method:

```lua
function ExpService.Client.GetExp(player)
    return ExpService.GetPlayerExp(player)
end
```

Internally, Comet is creating a remote function named `GetExp` and binding it to this method. Thus, exposing it to the client. 

Let's access this service on the client and get our points:

```lua
-- On the client

local Comet = require(game:GetService("ReplicatedStorage").Comet)

local ExpService = Comet.GetService("ExpService")
print(ExpService.GetExp()) --> 0
```

### Exposing and using Signals

Comet also allows you to expose signals to the client, except that the signal is created through the [RemoteSignal](https://github.com/angrybino/Comet/blob/master/src/Util/Shared/Remote/RemoteSignal.lua) module. (Read more about it [here]())

So what if we wanted to fire a signal to the player everytime their exp was set? First, let's create remote signal `OnExpSet` and expose it to the client. Again, we'll do it in the `Init` method:

```lua
function ExpService.Init()
    -- Previous code
    local RemoteSignal = require(ExpService.Comet.Util.Shared.Remote.RemoteSignal)
    ExpService.Client.OnExpSet = RemoteSignal.new()
end
```

Internally, Comet is creating a remote event named `OnExpSet` and binding it to this remote signal.

Now, let's fire it to the player who gets their exp set:

```lua
ExpService.OnPlayerExpSet:Connect(function(player, exp)
     print(("%s's exp was set to %d"):format(player.Name, exp))
    ExpService.Client.OnExpSet:Fire(player, exp)
end)  
```

### Exposing and using Properties

Finally, Comet allows you to expose properties to the client through the [RemoteProperty](https://github.com/angrybino/Comet/blob/master/src/Util/Shared/Remote/RemoteProperty.lua) module. (Read more about it [here]()).

Let's suppose we want to tell who has the highest exp to the client. First, let's create a remote property `GetPlayerWithHighestPoints`. Again, we'll do it in the `Init` method:

```lua
function ExpService.Init()
    -- Previous code
    local RemoteProperty = require(ExpService.Comet.Util.Shared.Remote.RemoteProperty)
    ExpService.Client.GetPlayerWithHighestPoints = RemoteProperty.new()  
end
```

Internally, Comet is creating a remote function named `GetPlayerWithHighestPoints` and binding it to this remote property.

Now, let's change the `SetPlayerExp` method to set the value of the remote property to the player who has the highest points.

```lua
local Players = game:GetService("Players")

function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
    ExpService.OnPlayerExpSet:Fire(player.Name, exp)
    
    local highestExp, player = 0, nil

    for playerName, exp in pairs(ExpService.PlayerExpData) do
        if exp > highestExp then
            highestExp = exp
            player = Players[playerName]
        end
    end

    ExpService.Client.GetPlayerWithHighestPoints:SetValue(player)
end
```

Let's access this service on the client and grab the value of `GetPlayerWithHighestPoints`:

```lua
-- On the client

local Comet = require(game:GetService("ReplicatedStorage").Comet)

local ExpService = Comet.GetService("ExpService")
local highestPointsPlayer = ExpService.GetPlayerWithHighestPoints()

ExpService.GetPlayerWithHighestPoints.OnValueUpdate:Connect(function(player)
    highestPointsPlayer = player
end
```