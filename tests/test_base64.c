#include <assert.h>
#include <stdlib.h>
#include <string.h>

#include "../src/base64.h"

static int
equal_strings(const char* str1, const char* str2)
{
	return strcmp(str1, str2) == 0;
}

void
test_encode_returns_expected_string()
{
	const char proxy_auth[] = "user1:password1";
	char* encoded = base64_encode(proxy_auth, sizeof(proxy_auth) - 1);

	assert(equal_strings(encoded, "dXNlcjE6cGFzc3dvcmQx"));

	free(encoded);
	encoded = NULL;
}

int
main()
{
	test_encode_returns_expected_string();

	return 0;
}
