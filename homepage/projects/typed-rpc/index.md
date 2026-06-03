typed-rpc
=========

A lightweight, type-safe JSON-RPC 2.0 framework for Haskell. Build RPC services with compile-time guarantees on API contracts using advanced Haskell type system features.

## Download

[typed-rpc-0.1.0.tar.gz](https://github.com/mistivia/releases/releases/download/typed-rpc-0.1.0/typed-rpc-0.1.0.tar.gz)

## Quick Start

### Import Dependencies

    {-# LANGUAGE OverloadedStrings #-}

    import TypedRpc (Service, service, api, makeApplication, ApiCmd, Apis, TypedRpcResp)
    import Data.Text (Text)
    import Network.Wai (Request)
    import Network.Wai.Handler.Warp (run)
    import Data.FlexRecord (FlexRecord, Field, frGet, flexRecord, field)
    import Data.FlexRecord.Json ()

### Define API Types

Use [flex-record](https://github.com/mistivia/flex-record) for structured input/output (or any `FromJSON`/`ToJSON` type):

    type HelloInput = FlexRecord 
        [ Field "name" Text
        , Field "email" (Maybe Text)
        ]
    type HelloOutput = FlexRecord '[ Field "message" Text]

    type EchoInput = FlexRecord '[Field "content" Text]
    type EchoOutput = FlexRecord '[Field "echoed" Text]

    mkHelloOutput :: Text -> HelloOutput
    mkHelloOutput msg = flexRecord $ field @"message" msg

    mkEchoOutput :: Text -> EchoOutput
    mkEchoOutput echoed = flexRecord $ field @"echoed" echoed

### Write API Handlers

    helloHandler :: Request -> HelloInput -> TypedRpcResp HelloOutput
    helloHandler _req input = do
        let name = frGet @"name" input
            mEmail = frGet @"email" input
            greeting = case mEmail of
                Just email -> "Hello, " <> name <> "! Your email is: " <> email
                Nothing -> "Hello, " <> name <> "!"
        pure $ Right (mkHelloOutput greeting)

    echoHandler :: Request -> EchoInput -> TypedRpcResp EchoOutput
    echoHandler _req input = do
        let content = frGet @"content" input
        pure $ Right (mkEchoOutput content)

### Build the Service

    type MyServiceApi = Apis
    '[ ApiCmd "hello" HelloInput HelloOutput
        , ApiCmd "echo" EchoInput EchoOutput
        ]

    myService :: Service MyServiceApi
    myService = service 
        $ api @"hello" helloHandler
        . api @"echo" echoHandler

### Run the Server

    main :: IO ()
    main = do
        run 18888 (makeApplication myService)

## Making Requests

The server accepts standard JSON-RPC 2.0 requests:

    curl -X POST http://localhost:18888 \
    -H "Content-Type: application/json" \
    -d '{
        "jsonrpc": "2.0",
        "method": "hello",
        "params": {"name": "Alice", "email": "alice@example.com"},
        "id": 1
    }'

Response:

    {
    "jsonrpc": "2.0",
    "result": {"message": "Hello, Alice! Your email is: alice@example.com"},
    "id": 1
    }

## Requirements

- GHC 9.x with GHC2024 support

## Running the Demo

    nix develop --command cabal run typed-rpc-demo

## Running Tests

    nix develop --command cabal test
