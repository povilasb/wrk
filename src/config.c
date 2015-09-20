#include "config.h"

bool
config_proxy_set(const struct config* cfg)
{
	return (cfg->proxy_addr[0] != '\0') && (cfg->proxy_port[0] != '\0');
}
