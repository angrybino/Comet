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
    - The `Client` table is optional. However, it is good practice to keep it.

## `Init` and `Start` methods

These methods are optional. To learn more about them, see the [lifecycle guide](Lifecycle.md).

## Injected members

Members that are injected when a service is initialized (see the [lifecycle guide](Lifecycle.md)).

| Injected Members      | Description                          |
| ----------- | ------------------------------------ |
| `Comet`       | The reference to the required Comet module  |