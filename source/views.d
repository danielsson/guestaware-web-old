module views;
import std.array;
import std.variant;
import vibe.d;
import mysql.db;
import models;

void index(HttpServerRequest req, HttpServerResponse res) {
	res.render!("index.dt");
}

void home(HttpServerRequest req, HttpServerResponse res) {
	auto user = GAUser.fromString(req.session["user"]);
	auto con = DBContainer.instance.lockConnection();

	auto events = GAEvent.byUser(con, user);

	res.render!("home.dt", events);
}

void login(HttpServerRequest req, HttpServerResponse res) {
	if(! (req.session is null)) { // There is already a session in place
		res.redirect("/home");
		return;
	}

	string error = "";

	switch(req.method) {
	case HttpMethod.POST:

		auto con = DBContainer.instance.lockConnection();

		auto users = GAUser.byUsername(con, req.form["username"]);

		if(users.length == 1 && users[0].passwordEquals(req.form["password"])) {
			// The username existed and the password matches
			auto session = res.startSession();

			session["user"] = users[0].toString();

			res.redirect("/home");
			return;
		}

		error = "Unknown username/password";
		goto case;
	case HttpMethod.GET:
		res.render!("login.dt", error);
		break;
	default:
		throw new HttpStatusException(405, "Unsupported request method");
	}
	
}

void showEvent(HttpServerRequest req, HttpServerResponse res) {
	return;
}