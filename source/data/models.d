module guestaware.data.models;

abstract class Model {
	this() {

	}
}

class User : Model {
	public string _id;
	public string username;
	public string passwordHash;
	public string code;

	this(string uname, string pass) {
		username = uname;
		setPassword(pass);
	}

	void setPassword(string new_pass) {
		passwordHash = generateSimplePasswordHash(new_pass, "$dff");
	}

	bool checkPassword(string pass) {
		return testSimplePasswordHash(passwordHash, pass, "$dff");
	}

	Bson toBson() {
		if(_id is null) {
			return Bson([
				"username": Bson(username),
				"password": Bson(passwordHash),
				"code": Bson(code)]);
		} else {
			return Bson([
				"_id": BsonObjectId(_id),
				"username": Bson(username),
				"password": Bson(passwordHash),
				"code": Bson(code)]);
		}
	}



}