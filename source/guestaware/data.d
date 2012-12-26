module guestaware.data;

import vibe.d;

class Database {
	private static MongoDB db;
	
	public static MongoDB instance() {
		if(db is null) {
			db = connectMongoDB("127.0.0.1");
		}

		return db;
	}
}