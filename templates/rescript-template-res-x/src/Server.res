let start = (~port) =>
  Bun.serve({
    port,
    development: ResX.BunUtils.isDev,
    routes: {
      let liveRoute: Bun.routeHandlerObject = {
        get: Static(Response.make("live", ~options={status: 200})),
      }
      let readyRoute: Bun.routeHandlerObject = {
        get: Static(Response.make("ready", ~options={status: 200})),
      }

      Dict.assign(
        ResXAssets.staticAssetRoutes,
        dict{
          "/health/live": liveRoute,
          "/health/ready": readyRoute,
        },
      )
    },
    fetch: async (request, _server) => {
      let url = request->Request.url->URL.make

      switch url->URL.pathname {
      | "/health/live" =>
        Response.make(
          "live",
          ~options={
            status: 200,
            headers: FromDict(
              dict{
                "Content-Type": "text/plain; charset=utf-8",
              },
            ),
          },
        )
      | "/health/ready" =>
        Response.make(
          "ready",
          ~options={
            status: 200,
            headers: FromDict(
              dict{
                "Content-Type": "text/plain; charset=utf-8",
              },
            ),
          },
        )
      | _ =>
        await Handler.handler.handleRequest({
          request,
          setupHeaders: () =>
            Headers.make(~init=FromArray([("Content-Type", "text/html; charset=utf-8")])),
          onBeforeSendResponse: async ({response, context: _}) => {
            switch (
              response->Response.headers->Headers.get("Cache-Control"),
              request->Request.method,
            ) {
            | (None, GET) =>
              // Cache everything without an explicit cache control set for 15 mins
              response
              ->Response.headers
              ->Headers.set(
                "Cache-Control",
                ResX.Utils.CacheControl.make(
                  ~cacheability=Public,
                  ~expiration=[MaxAge(Minutes(15.))],
                  ~revalidation=[StaleWhileRevalidate(Minutes(15.))],
                ),
              )
            | _ => ()
            }

            response
          },
          render: async ({path}) =>
            switch path {
            | list{"sitemap.xml"} => <SiteMap />
            | list{"robots.txt"} => <RobotsTxt />
            | _ =>
              <Html>
                {switch path {
                | list{} => <PageHome />
                | list{"setup"} => <PageSetup />
                | list{"examples"} => <PageExamples />
                | list{"resources"} => <PageResources />
                | _ => <PageFourOhFour />
                }}
              </Html>
            },
        })
      }
    },
  })
