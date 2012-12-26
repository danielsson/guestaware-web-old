import vibe.d;
static import views;

void checkLogin(HttpServerRequest req, HttpServerResponse res) {
	if(req.session is null) {
		res.redirect("/login");
	}
}

static this()
{
	auto router = new UrlRouter;
	router
		.get("/", &views.index)
		
		.any("/login", &views.login)
		.get("*", serveStaticFiles("./public/"))

		.any("*", &checkLogin)
		.get("/home", &views.home);

	auto settings = new HttpServerSettings;
	settings.sessionStore = new MemorySessionStore;
	settings.port = 8080;
	
	listenHttp(settings, router);
}
