# Lifecycle 

Comet's life cycle consists of initializing and starting up controllers (client) and services (server), and performing other internal work.

# Order of operations

## Server

- All services nested inside the folder set by `Comet.SetServicesFolder()` are required.
- All services are now initialized and the `Init` method on all services are called, if found. Any errors will be captured from the `Init` method and fed to the promise returned by `Comet.Start()`. Note that during this time, accessing other services is safe, but working with them is not.
- After all services have their `Init` method called and completed, they are started and the `Start` method is called on all services in a new coroutine. Finally, working with other services is now safe.
- The promise returned by `Comet.Start()` is resolved.

## Client

- All controllers nested inside the folder set by `Comet.SetControllersFolder()` are required.
- All controllers are now initialized and the `Init` method on all controllers are called, if found. Any errors will be captured from the `Init` method and fed to the promise returned by `Comet.Start()`. Note that during this time, accessing other controllers is safe, but working with them is not.
- After all controllers have their `Init` method called and completed, they are started and the `Start` method is called on all controllers in a new coroutine. Finally, working with other controllers is now safe.
- The promise returned by `Comet.Start()` is resolved.