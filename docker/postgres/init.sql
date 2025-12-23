-- Initialize Backstage database
CREATE DATABASE backstage_plugin_catalog;
CREATE DATABASE backstage_plugin_scaffolder;
CREATE DATABASE backstage_plugin_auth;
CREATE DATABASE backstage_plugin_search;
CREATE DATABASE backstage_plugin_techdocs;
CREATE DATABASE "backstage_plugin_branding-settings";

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE backstage_plugin_catalog TO backstage;
GRANT ALL PRIVILEGES ON DATABASE backstage_plugin_scaffolder TO backstage;
GRANT ALL PRIVILEGES ON DATABASE backstage_plugin_auth TO backstage;
GRANT ALL PRIVILEGES ON DATABASE backstage_plugin_search TO backstage;
GRANT ALL PRIVILEGES ON DATABASE backstage_plugin_techdocs TO backstage;
GRANT ALL PRIVILEGES ON DATABASE "backstage_plugin_branding-settings" TO backstage;
