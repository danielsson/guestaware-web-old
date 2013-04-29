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

/// Selector
struct Select {
	static ModelSet!T byId(T)(Connection con, uint id) {
		return where!T(con, " WHERE id = ? LIMIT 1;", Variant(id));
	}

	static ModelSet!T whereEquals(T)(Connection con, string field, Variant va) {
		return where!T(con, " WHERE "~field~" = ?;", va);
	}

	static ModelSet!T where(T)(Connection con, string whereStr, Variant[] va ...) {
		auto cmd = Command(con, T.MYX_SEL_QUERY ~ whereStr);
		cmd.prepare();
		cmd.bindParameters(va);

		return ModelSet!T(cmd);
	}
}

struct Insert {
	static bool model(T)(Connection con, T t) {
		auto cmd = Command(con, "INSERT INTO " ~ T.MYX_INSERT);
		cmd.prepare();
		cmd.bindParameters(t.toVariant());

		return cmd.execPrepared();
	}
}

struct Update {
	static bool model(T)(Connection con, T t) {
		auto cmd = Command(con,
			"UPDATE " ~ T.MYX_UPDATE ~ " WHERE id=? LIMIT 1;");
		cmd.prepare();
		cmd.bindParameters(t.toVariant() ~ Variant(t.id));

		return cmd.execPrepared();
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

public	ResultSet	_results;
private	T			_t;

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

	Variant[] toVariant() {
		return variantArray(uid, name, venue, date);
	}

static:
	const string MYX_SEL_QUERY = "SELECT * FROM ga_event";
	const string MYX_INSERT =
		"ga_event (uid, name, venue, date) VALUES (?,?,?,?)";
	const string MYX_UPDATE =
		"ga_event SET uid=?, name=?, venue=?, date=?";

	ModelSet!GAEvent byUser(Connection con, ref GAUser user) {
		return Select.whereEquals!GAEvent(con, "uid", Variant(user.id));
	}
}


/// Guests
struct GAGuest {
	uint id;
	uint eid;
	string name;
	string email;
	string phone;
	string note;
	ushort checked;

	Variant[] toVariant() {
		return variantArray(eid, name, email, phone, note, checked);
	}

static:
	const string MYX_SEL_QUERY = "SELECT * FROM ga_guest";
	const string MYX_INSERT =
		"ga_guest (eid, name, email, phone, note, checked) VALUES (?,?,?,?,?,?)";
	const string MYX_UPDATE =
		"ga_guest SET eid=?, name=?, email=?, phone=?, note=?, checked=?";

	ModelSet!GAGuest byEvent(Connection con, GAEvent evt) {
		return Select.whereEquals!GAGuest(con, "eid", Variant(evt.id));
	} 
}

struct GAUser {
	uint id;
-	string username;
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

	Variant[] toVariant(bool includeId) {
		return variantArray(username, password);
	}

static:
	const string MYX_SEL_QUERY = "SELECT * FROM ga_user";
	const string MYX_INSERT =
		"ga_user (username, password) VALUES (?, ?)";
	const string MYX_UPDATE =
		"ga_user SET username=?, password=?";

	ModelSet!GAUser byUsername(Connection con, string username) {
		return Select.where!GAUser(
			con, " WHERE username=? LIMIT 1;", Variant(username));
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