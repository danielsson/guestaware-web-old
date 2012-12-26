module views;
import vibe.d;

void index(HttpServerRequest req, HttpServerResponse res) {
	res.render!("index.dt");
}

void home(HttpServerRequest req, HttpServerResponse res) {
	res.render!("home.dt");
}

void login(HttpServerRequest req, HttpServerResponse res) {
	switch(req.method) {
	case HttpMethod.GET:
		res.render!("login.dt");
		break;
	case HttpMethod.POST:
		auto session = res.startSession();
		
		session["username"] = req.form["username"];
		session["password"] = req.form["password"];
		session["userlevel"] = "1";

		res.redirect("/home");
		break;
	default:
		throw new HttpStatusException(405, "Unsupported request method");
	}
	
}