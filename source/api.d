module api;
import std.variant;
import std.array;
import vibe.d;
import models;
import mysql.db;

private T[] getTypeArray(T)(ref ModelSet!T set) {
	T[] retval;
	retval.length = set.length;
	for(uint i = 0, len = set.length; i < len; i++) {
		T t = set[i];
		retval[i] = t;
	}
	return retval;
}

interface IGAAPI {
	string[string] getStatus();

	@property IGAGuestAPI guest();

	@property IGAEventAPI event();
}

interface IGAEventAPI {
	Json getIndex();
	Json putIndex();
	GAEvent[] getIndex(int id);
	Json putIndex(int id);

	GAGuest[] getGuests(int id);
}

interface IGAGuestAPI {
	Json putIndex();
	Json index(int id);
	Json postIndex(int id);
}

class GAEventAPI : IGAEventAPI {
	Json getIndex() {
		return Json.EmptyObject;
	}

	//GET POST	/api/event/:id 			get a event, update a event
	Json putIndex() {
		return Json.EmptyObject;
	}

	GAEvent[] getIndex(int id) {
		auto con = DBContainer.instance.lockConnection();
		auto events = Select.byId!GAEvent(con, id);
		
		return getTypeArray!GAEvent(events);
	}
	Json putIndex(int id) {
		return Json.EmptyObject;
	}

	GAGuest[] getGuests(int id) {
		auto con = DBContainer.instance.lockConnection();
		auto guests = Select.whereEquals!GAGuest(con, "eid", Variant(id));

		return getTypeArray!GAGuest(guests);
	}
}

class GAGuestAPI : IGAGuestAPI {
	Json putIndex() {
		return Json.EmptyObject;
	}
	Json index(int id) {
		return Json.EmptyObject;
	}
	Json postIndex(int id) {
		return Json.EmptyObject;
	}
}

class GAAPI : IGAAPI {
	private GAGuestAPI guest_api;
	private GAEventAPI event_api;

	this() {
		guest_api = new GAGuestAPI;
		event_api = new GAEventAPI;
	}

	string[string] getStatus() {
		return ["status":"OK"];
	}

	@property IGAGuestAPI guest() {
		return guest_api;
	}

	@property IGAEventAPI event() {
		return event_api;
	}
}

/*
GET			/api/status
PUT			/api/guest 				create a guest 
GET POST	/api/guest/:id 			get a guest, update a guest
GET PUT 	/api/event				get all events, create new event
GET POST	/api/event/:id 			get a event, update a event
GET			/api/event/:id/guests 	get all guests for event

*/

