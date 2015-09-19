#include <stdio.h>
#include <setjmp.h>
#include <stdarg.h>
#include <assert.h>

#include "../src/cli_options.h"
#include "../src/config.h"
#include "../src/http_parser.h"
#include "../src/zmalloc.h"

int
equal_strings(const char* str1, const char* str2)
{
	return strcmp(str1, str2) == 0;
}

static void
test_parse_args_sets_url()
{
	struct config cfg;
	char* argv[] = {
		"wrk",
		"http://google.com",
		"\0"
	};
	int argc = 2;

	char* headers[] = {NULL};
	struct http_parser_url parts = {};
	char* url = NULL;

	parse_args(&cfg, &url, &parts, headers, argc, argv);

	assert(equal_strings(url, "http://google.com"));
}

int
main(int argc, char *argv[])
{
	test_parse_args_sets_url();
}
