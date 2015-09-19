#include <assert.h>

#include "../src/script.h"

static int
equal_strings(const char* str1, const char* str2)
{
	return strcmp(str1, str2) == 0;
}

void
test_create_script_sets_appropriate_http_path()
{
	char headers[2][64] = {"", ""};
	lua_State* lua_vm =
		script_create(NULL, "http://site.com/test/page1.html", headers,
			false, false);

	lua_getglobal(lua_vm, "wrk");
	lua_getfield(lua_vm, -1, "path");

	const char* path = lua_tostring(lua_vm, -1);
	assert(equal_strings(path, "/test/page1.html"));
}

void
test_create_script_sets_http_path_same_to_url_when_proxy_is_set()
{
	char headers[2][64] = {"", ""};
	lua_State* lua_vm =
		script_create(NULL, "http://site.com/test/page1.html", headers,
			false, true);

	lua_getglobal(lua_vm, "wrk");
	lua_getfield(lua_vm, -1, "path");

	const char* path = lua_tostring(lua_vm, -1);
	assert(equal_strings(path, "http://site.com/test/page1.html"));
}


int
main()
{
	test_create_script_sets_appropriate_http_path();
	test_create_script_sets_http_path_same_to_url_when_proxy_is_set();

	return 0;
}
