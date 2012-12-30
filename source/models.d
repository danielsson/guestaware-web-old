module models;

import mysql.db;
import std.variant;
import std.datetime;
import std.array;
import std.string;
import std.conv;
import vibe.crypto.md5;

//Utils

///Db singleton
struct DBContainer {
	static bool _is_set = false;
	static MysqlDB _db;
	@property static ref MysqlDB instance() {
		if(!_is_set) {
			_db = new MysqlDB("localhost", "default", "default", "default");
			_is_set = true;
		}
		return _db;
	}
}
/**
 * This is a iterator for a ResultSet that returns the rows
 * as a struct of the type T.
 *
 * Example
 * ---
 *  struct User {...}
 *  ResultSet results = command.exec...
 *  foreach(User user; ModelSet!User(results)) {
 *	  writeln(user.name);
 *  }
 */
struct ModelSet(T)
{
private:
	ResultSet	_results;
	T			_t;

public:
	this(ResultSet rs) {
		_results = rs;
		_t = T();
	}
	this(ref Command cmd) {
		this(cmd.execPreparedResult());
	}

	// We dont need to do anything about these functions
	@property bool empty() {return _results.empty;}
    @property ModelSet!T save() {return this;}
	@property size_t length() {return _results.length;}
	void popFront() {return _results.popFront();}
	void popBack() {return _results.popBack();}

	//Special
	@property T front() {
		_results.front.toStruct!T(_t);
		return _t;
	}
	
	@property T back() {
		_results.back.toStruct!T(_t);
		return _t;
	}
	
	T opIndex(size_t i) {
		_results.opIndex(i).toStruct!T(_t);
		return _t;
	}
}

/**
 * Functions to manage events
 */

/// Event
struct GAEvent {
	uint id;
	uint uid;
	string name;
	string venue;
	DateTime date;

	static const string MYX_SEL_QUERY = "SELECT * FROM ga_event";
	static const string MYX_INSERT_QUERY =
		"INSERT INTO ga_event (name, venue, date) VALUES (?, ?, ?)";
	
	static GAEvent byId(Connection con, uint id) {
		auto cmd = Command(con, MYX_SEL_QUERY ~ " WHERE id = ? LIMIT 1;");
		cmd.prepare();

		Variant[1] va;
		va[0] = id;
		cmd.bindParameters(va);
		
		auto results = cmd.execPreparedResult();

		if (results.length == 0) 
			throw new Exception("Not found");

		GAEvent evt;
		results[0].toStruct!GAEvent(evt);
		return evt;
	}

	static ModelSet!GAEvent byUser(Connection con, ref GAUser user) {
		auto cmd = Command(con, MYX_SEL_QUERY ~ " WHERE uid = ?;");
		cmd.prepare();

		Variant[1] va;
		va[0] = user.id;
		cmd.bindParameters(va);

		return ModelSet!GAEvent(cmd);
	}
}


/// Guests
struct GAGuest {
	uint id;
	string name;
	bool checkedIn;
}


struct GAUser {
	uint id;
	string username;
	string password; // This must be the hash


	bool passwordEquals(string pass) {
		return md5(pass) == password.toUpper();
	}

	void setPassword(string pass) {
		password = md5(pass);
	}

	//Unsafe implementation
	@system string toString() {
		return id.to!(string)() ~ "|$$|" ~ username ~ "|$$|" ~ password;
	}

static:
	const string MYX_SEL_QUERY = "SELECT * FROM ga_user";
	const string MYX_INSERT_QUERY =
		"INSERT INTO ga_user (username, password) VALUES (?, ?)";

	ModelSet!GAUser byUsername(Connection con, string username) {
		auto cmd = Command(con, MYX_SEL_QUERY ~ " WHERE username=? LIMIT 1;");
		cmd.prepare();

		Variant[1] va;
		va[0] = username;
		cmd.bindParameters(va);

		return ModelSet!GAUser(cmd);
	}

	ModelSet!GAUser byId(Connection con, uint id) {
		auto cmd = Command(con, MYX_SEL_QUERY ~ " WHERE id=? LIMIT 1;");
		cmd.prepare();

		Variant[1] va;
		va[0] = id;
		cmd.bindParameters(va);

		return ModelSet!GAUser(cmd);
	}

	GAUser fromString(string str) {
		auto g = split!(string,string)(str, "|$$|");
		GAUser u;
		u.id = g[0].to!uint();
		u.username = g[1];
		u.password = g[2];
		return u;
	}
}