# Services

Services are singletons that serve a specific purpose on the server. For e.g, you may have a `PlayerData` service, which manages player data in your game. Remember that services serve as the backbones of your game!

In this section, we'll gradually create a basic service which manages player experience.

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

Members that are injected when a service is [initialized](Lifecycle.md). 

| Injected Members      | Description                          |
| ----------- | ------------------------------------ |
| `Comet`       | The reference to the required Comet module  |

## Adding methods and members

A service at it's core is just a `ModuleScript`, so treat it as such. With this knowledge in mind, we can add a few methods to manage player experience:

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

Let's change the methods we created to use this new member:

```lua
function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
end

function ExpService.GetPlayerExp(player)
    -- Get player exp and if it doesn't exist, set it to 0
    ExpService.PlayerExpData[player.Name] = ExpService.PlayerExpData[player.Name] or 0
    return ExpService.PlayerExpData[player.Name]
end
```

## Using signals

What if we wanted to know whenever a player's experience was set? Well, we need a signal which will be fired everytime `SetPlayerExp` is called and then we can just listen to the signal. 

Let's create a signal `OnPlayerExpSet`:

```lua
function ExpService.Init()
    local Signal = require(ExpService.Comet.Util.Shared.Signal)

    ExpService.OnPlayerExpSet = Signal.new()
    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("%s's exp was set to %d"):format(playerName, exp))
    end)
end
```

Now let's change the `SetPlayerExp` method to fire this signal whenever it is called:

```lua
function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
    ExpService.OnPlayerExpSet:Fire(player.Name, exp)
end
```

Then, some other services can access this signal like so:
```lua
-- Some other service..

function SomeOtherService.Start()
    local ExpService = SomeOtherService.Comet.GetService("ExpService")
    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("Exp changed for %s to %d"):format(playerName, exp))
    end)
end
```

Finally, let's clear out the player's experience from `PlayerExpData` when the player leaves:

```lua
function ExpService.Init()
    local Signal = require(ExpService.Comet.Util.Shared.Signal)

    ExpService.OnPlayerExpSet = Signal.new()
    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("%s's exp was set to %d"):format(playerName, exp))
    end)

    game:GetService("Players").PlayerRemoving:Connect(function(player)
        ExpService.PlayerExpData[player.Name] = nil
    end)
end
```

## Server-client communication

### The `Client` table

Before we move any further, we need to  finally discuss the purpose of the `Client` table in a service. This is the table where you store anything you want to expose to the client, and this is what the client will see when they access a service!

## Exposing methods

What if the client wants to know how much experience it has currently? This would require communication between the server and the client, and luckily for you, Comet efficiently abstracts this from the developer (this is also the main reason why Comet was made!).

Exposing a method to the client is very easy. First, let's create a method `GetExp` in the `Client` table:

```lua
function ExpService.Client.GetExp(player)

end
```

Internally, Comet binds a remote function `GetExp` to this method. 

!!!note
    Since a remote function is binded to a client exposed method, the first argument internally passed to the method will be the player who called it.

We can then return the experience back to the caller (client).

```lua
function ExpService.Client.GetExp(player)
    return ExpService.GetPlayerExp(player)
end
```

On the client, we can call this method as such:

```lua
local Comet = require(game:GetService("ReplicatedStorage").Comet)

local ExpService = Comet.GetService("ExpService")

local currentExp = ExpService.GetExp()
print(currentExp) --> 0 (starting value)
```

## Exposing signals

Okay, now we something to tell the client whenever their experience is set. We need to expose a signal to the client, and in order to accomplish this, we need to use the [RemoteSignal](https://github.com/angrybino/Comet/blob/master/src/Util/Shared/Remote/RemoteSignal.lua) module (read more about it [here](Util/Remote/RemoteSignal.md)).

Let's create a `RemoteSignal` object `OnExpSet` in the `Client` table:

```lua
function ExpService.Init()
    -- Previous code --
    local RemoteSignal = require(ExpService.Comet.Util.Shared.Remote.RemoteSignal)

    ExpService.Client.OnExpSet = RemoteSignal.new()
end
```

Now, let's fire off this object to the client whenever their experience is set by the `SetPlayerExp` method:

```lua
function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
    ExpService.OnPlayerExpSet:Fire(player.Name, exp)
    
    ExpService.Client.OnExpSet:Fire(player, exp)
end
```

On the client, we can now keep track of our experience whenever it is updated:

```lua
local Comet = require(game:GetService("ReplicatedStorage").Comet)

local ExpService = Comet.GetService("ExpService")

local currentExp = ExpService.GetExp()

ExpService.OnExpSet:Connect(function(newExp)
    currentExp = newExp
end)
```

## Exposing properties

Finally,

## Completed examples

### ExpService

```lua
local ExpService = {
    Client = {}
}

function ExpService.Init()
    local Signal = require(ExpService.Comet.Util.Shared.Signal)
    local RemoteSignal = require(ExpService.Comet.Util.Shared.Remote.RemoteSignal)

    ExpService.OnPlayerExpSet = Signal.new()
    ExpService.Client.OnExpSet = RemoteSignal.new()

    ExpService.OnPlayerExpSet:Connect(function(playerName, exp)
        print(("%s's exp was set to %d"):format(playerName, exp))
    end)

    game:GetService("Players").PlayerRemoving:Connect(function(player)
        ExpService.PlayerExpData[player.Name] = nil
    end)
end

function ExpService.SetPlayerExp(player, exp)
    ExpService.PlayerExpData[player.Name] = exp
    ExpService.OnPlayerExpSet:Fire(player.Name, exp)

    ExpService.Client.OnExpSet:Fire(player, exp)
end

function ExpService.GetPlayerExp(player)
    -- Get player exp and if it doesn't exist, set it to 0
    ExpService.PlayerExpData[player.Name] = ExpService.PlayerExpData[player.Name] or 0
    return ExpService.PlayerExpData[player.Name]
end

function ExpService.Client.GetExp(player)
    return ExpService.GetPlayerExp(player)
end

return ExpService
```

### Client consumer

```lua
local Comet = require(game:GetService("ReplicatedStorage").Comet)

local ExpService = Comet.GetService("ExpService")

local currentExp = ExpService.GetExp()

ExpService.OnExpSet:Connect(function(newExp)
    currentExp = newExp
end)
```