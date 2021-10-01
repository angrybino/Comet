# Services

Services are singletons that serve a specific purpose on the server. For e.g, you may have a `PlayerData` service, which manages player data in your game. Services serve as the backbones of your game, they can communicate with each other, expose values to the client, etc.

In this section, we'll gradually create a service which manages player data.

## Creating services

A service is simply a `ModuleScript` in it's simplest form:

```lua
local PlayerDataService = {
    Client = {}
}

function PlayerDataService.Init()

end

function PlayerDataService.Start()

end

return PlayerDataService
```

!!! note "Note"
    - The name of the service will be the name of the module script it is nested in.
    - The `Client` table is optional. However, it is good practice to keep it.

## `Init` and `Start` methods

These methods are optional. To learn more about them, see the [lifecycle]() guide.

## Injected members

Members that are injected when the service is initialized.

| Injected Members      | Description                          |
| ----------- | ------------------------------------ |
| `Comet`       | The reference to the required Comet module  |

## Adding methods / members

Remember that a service is just a `ModuleScript`, so make sure to treat them as such. So we can  add more methods to `MyService`:

```lua
local PlayerDataService = {
    Client = {}
}

function PlayerDataService.Init()

end

function PlayerDataService.Start()

end

function PlayerDataService._loadPlayerData(key)
   
end

return PlayerDataService
```

